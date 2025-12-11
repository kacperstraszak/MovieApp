import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.200.0/http/server.ts';

interface UserPreference {
  userId: string;
  movieId: number;
  rating: number;
  interactionType: string;
}

interface GenrePreference {
  genreId: number;
  totalScore: number;
  userCount: number;
  avgScore: number;
}

serve(async (req: Request) => {
  try {
    const { groupId } = await req.json();
    if (!groupId) {
      return new Response(
        JSON.stringify({ success: false, error: 'groupId required' }), 
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const TMDB_API_KEY = Deno.env.get('TMDB_API_KEY')!;

    if (!TMDB_API_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'TMDB_API_KEY not configured' }), 
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const isV4Token = TMDB_API_KEY.startsWith('eyJ');
    const tmdbHeaders = isV4Token 
      ? { 'Authorization': `Bearer ${TMDB_API_KEY}`, 'Content-Type': 'application/json' }
      : {};

    const buildTmdbUrl = (path: string) => {
      return isV4Token ? `https://api.themoviedb.org/3${path}` : `https://api.themoviedb.org/3${path}${path.includes('?') ? '&' : '?'}api_key=${TMDB_API_KEY}`;
    };

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const recent = await supabase
      .from('group_recommendations')
      .select('id')
      .eq('group_id', groupId)
      .gte('created_at', new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString())
      .limit(1);

    if (recent.error) throw recent.error;
    
    if (recent.data && recent.data.length > 0) {
      return new Response(
        JSON.stringify({ success: true, useExisting: true }), 
        { headers: { 'Content-Type': 'application/json' } }
      );
    }

    const { data: interactions, error: intErr } = await supabase
      .from('user_interactions')
      .select('user_id, movie_id, rating, interaction_type')
      .eq('group_id', groupId);

    if (intErr) throw intErr;
    
    if (!interactions || interactions.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No interactions found for group' }), 
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const seenMovieIds = new Set<number>(
      interactions.map((i: any) => i.movie_id).filter(Boolean)
    );

    const userPreferences = new Map<string, UserPreference[]>();
    
    interactions.forEach((i: any) => {
      const userId = i.user_id;
      if (!userPreferences.has(userId)) {
        userPreferences.set(userId, []);
      }
      
      let rating: number | null = null;
      rating = i.rating ?? 3;
      
      if (rating !== null) {
        userPreferences.get(userId)!.push({
          userId,
          movieId: i.movie_id,
          rating,
          interactionType: i.interaction_type
        });
      }
    });

    const userCount = userPreferences.size;
    const groupGenreScores = new Map<number, { total: number; users: Set<string> }>();

    for (const [userId, prefs] of userPreferences.entries()) {
      const topMovies = prefs
        .filter(p => p.rating >= 3.5)
        .sort((a, b) => b.rating - a.rating)
        .slice(0, 10);

      for (const pref of topMovies) {
        try {
          const url = buildTmdbUrl(`/movie/${pref.movieId}`);
          const movieResp = await fetch(url, { headers: tmdbHeaders });
          
          if (!movieResp.ok) continue;
          
          const movie = await movieResp.json();
          
          if (movie.genres) {
            movie.genres.forEach((g: any) => {
              if (!groupGenreScores.has(g.id)) {
                groupGenreScores.set(g.id, { total: 0, users: new Set() });
              }
              const genreData = groupGenreScores.get(g.id)!;
              genreData.total += pref.rating;
              genreData.users.add(userId);
            });
          }
        } catch (err) {
          console.error(`Error analyzing genre for movie ${pref.movieId}`, err);
        }
      }
    }

    const genrePreferences: GenrePreference[] = Array.from(groupGenreScores.entries())
      .map(([genreId, data]) => ({
        genreId,
        totalScore: data.total,
        userCount: data.users.size,
        avgScore: data.total / data.users.size
      }))
      .sort((a, b) => {
        const aConsensus = a.userCount / userCount;
        const bConsensus = b.userCount / userCount;
        if (Math.abs(aConsensus - bConsensus) > 0.3) return bConsensus - aConsensus;
        return b.avgScore - a.avgScore;
      });

    const topGenres = genrePreferences.slice(0, 5).map(g => g.genreId);

    const movieScores = new Map<number, { total: number; count: number }>();
    
    interactions.forEach((i: any) => {
      const rating = i.rating ?? 3;
      if (rating >= 3.5) {
        if (!movieScores.has(i.movie_id)) {
          movieScores.set(i.movie_id, { total: 0, count: 0 });
        }
        const score = movieScores.get(i.movie_id)!;
        score.total += rating;
        score.count += 1;
      }
    });

    const seedMovies = Array.from(movieScores.entries())
      .map(([movieId, score]) => ({
        movieId,
        avgRating: score.total / score.count,
        consensus: score.count / userCount
      }))
      .filter(m => m.avgRating >= 3.5)
      .sort((a, b) => {
        const aScore = a.consensus * 0.6 + (a.avgRating / 5) * 0.4;
        const bScore = b.consensus * 0.6 + (b.avgRating / 5) * 0.4;
        return bScore - aScore;
      })
      .slice(0, 15);

    const candidates = new Map<number, number>();

    const addCandidate = (id: number, weight: number) => {
      if (seenMovieIds.has(id)) return;
      candidates.set(id, (candidates.get(id) || 0) + weight);
    };

    for (const seed of seedMovies.slice(0, 10)) {
      const fetchCandidates = async (endpoint: string, weightFactor: number) => {
        for (let page = 1; page <= 2; page++) {
          try {
            const resp = await fetch(buildTmdbUrl(`/movie/${seed.movieId}/${endpoint}?page=${page}`), { headers: tmdbHeaders });
            if (!resp.ok) continue;
            const data = await resp.json();
            
            data.results?.forEach((m: any, idx: number) => {
              const globalIdx = (page - 1) * 20 + idx;
              const positionWeight = Math.max(0.1, (40 - globalIdx) / 40);
              const weight = weightFactor * positionWeight * seed.consensus * (seed.avgRating / 5);
              addCandidate(m.id, weight);
            });
          } catch (e) {}
        }
      };

      await fetchCandidates('similar', 0.5);
      await fetchCandidates('recommendations', 0.4);
    }

    if (topGenres.length > 0) {
      for (let page = 1; page <= 3; page++) {
        try {
          const url = buildTmdbUrl(`/discover/movie?with_genres=${topGenres.slice(0, 3).join(',')}&sort_by=vote_average.desc&vote_count.gte=500&page=${page}`);
          const resp = await fetch(url, { headers: tmdbHeaders });
          if (resp.ok) {
            const data = await resp.json();
            data.results?.forEach((m: any, idx: number) => {
              const globalIdx = (page - 1) * 20 + idx;
              const positionWeight = Math.max(0.1, (60 - globalIdx) / 60);
              const matchCount = (m.genre_ids || []).filter((g: number) => topGenres.includes(g)).length;
              addCandidate(m.id, 0.3 * positionWeight * (matchCount / Math.min(3, topGenres.length)));
            });
          }
        } catch (e) {}
      }

      for (let page = 1; page <= 2; page++) {
        try {
          const url = buildTmdbUrl(`/discover/movie?with_genres=${topGenres.slice(0, 2).join(',')}&sort_by=popularity.desc&vote_count.gte=1000&page=${page}`);
          const resp = await fetch(url, { headers: tmdbHeaders });
          if (resp.ok) {
            const data = await resp.json();
            data.results?.forEach((m: any, idx: number) => {
               addCandidate(m.id, 0.25 * Math.max(0.1, (40 - ((page - 1) * 20 + idx)) / 40));
            });
          }
        } catch (e) {}
      }
    }

    const fetchGeneral = async (endpoint: string, baseWeight: number, pages: number = 1) => {
      for (let page = 1; page <= pages; page++) {
        try {
          const resp = await fetch(buildTmdbUrl(`/movie/${endpoint}?page=${page}`), { headers: tmdbHeaders });
          if (resp.ok) {
            const data = await resp.json();
            data.results?.forEach((m: any, idx: number) => {
              addCandidate(m.id, baseWeight * Math.max(0.05, (20 * pages - ((page - 1) * 20 + idx)) / (20 * pages)));
            });
          }
        } catch (e) {}
      }
    };

    await fetchGeneral('now_playing', 0.15, 1);
    await fetchGeneral('popular', 0.1, 2);

    if (candidates.size === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No new movies to recommend' }), 
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const topCandidates = Array.from(candidates.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 20); 

    const candidateIds = topCandidates.map(([id]) => id);
    
    const { data: existingMovies } = await supabase
      .from('movies')
      .select('id')
      .in('id', candidateIds);

    const existingIds = new Set(existingMovies?.map((m: any) => m.id) || []);
    const missingIds = candidateIds.filter(id => !existingIds.has(id));

    if (missingIds.length > 0) {
      const moviesToInsert = [];
      for (const movieId of missingIds) {
        try {
          const resp = await fetch(buildTmdbUrl(`/movie/${movieId}`), { headers: tmdbHeaders });
          if (resp.ok) {
            const movie = await resp.json();
            moviesToInsert.push({
              id: movie.id,
              title: movie.title || 'Unknown',
              description: movie.overview || null,
              release: movie.release_date || null,
              poster_path: `https://image.tmdb.org/t/p/w500${movie.poster_path}` || null,
              genre_ids: movie.genres ? movie.genres.map((g: any) => g.id) : [],
              popularity: movie.popularity || 0,
              vote_average: movie.vote_average || 0,
              backdrop_path: `https://image.tmdb.org/t/p/w780${movie.backdrop_path}` || null,
              vote_count: movie.vote_count || null
            });
          }
        } catch (e) {
          console.error(`Failed to fetch metadata for movie ${movieId}`, e);
        }
      }

      if (moviesToInsert.length > 0) {
        await supabase.from('movies').insert(moviesToInsert);
      }
    }

    const recommendations = topCandidates.slice(0, 10).map(([movieId, score], idx) => ({
      group_id: groupId,
      movie_id: movieId,
      score: Math.round(score * 1000) / 1000,
      position: idx + 1,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    }));

    await supabase.from('group_recommendations').delete().eq('group_id', groupId);
    const { error: insErr } = await supabase.from('group_recommendations').insert(recommendations);

    if (insErr) throw insErr;

    return new Response(
      JSON.stringify({ 
        success: true, 
        count: recommendations.length,
        stats: {
          users: userCount,
          candidates: candidates.size
        }
      }), 
      { headers: { 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('Critical error in generate-recommendations:', err);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: (err as any).message || 'Internal Server Error' 
      }), 
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});