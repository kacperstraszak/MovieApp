import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'

Deno.serve(async (req) => {
  const supabaseURL = Deno.env.get('SUPABASE_URL') as string
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') as string
  const tmdbApiKey = Deno.env.get('TMDB_API_KEY_READ')

  const supabase = createClient(supabaseURL, serviceKey)

  const url = new URL(req.url)
  const pagesToFetch = parseInt(url.searchParams.get('pages') || '5')

  console.log('--- STARTING IMPORT (WITH BACKDROPS) ---')

  const tmdbOptions = {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${tmdbApiKey}`
    }
  }

  try {
    const genresResponse = await fetch(
      `https://api.themoviedb.org/3/genre/movie/list?language=en-US`,
      tmdbOptions
    )
    if (genresResponse.ok) {
      const genresJson = await genresResponse.json()
      if (genresJson.genres) {
        await supabase
          .from('genres')
          .upsert(genresJson.genres, { onConflict: 'id', ignoreDuplicates: true })
      }
    }

    let totalImported = 0
    
    for (let page = 1; page <= pagesToFetch; page++) {
      console.log(`Fetching movies page ${page}...`)
      const tmdbResponse = await fetch(
        `https://api.themoviedb.org/3/discover/movie?language=en-US&sort_by=popularity.desc&page=${page}&vote_count.gte=200`,
        tmdbOptions
      )

      if (!tmdbResponse.ok) continue

      const tmdbJson = await tmdbResponse.json()
      
      const movies = tmdbJson.results.map((movie: any) => ({
        id: movie.id,
        title: movie.title,
        description: movie.overview,
        release: movie.release_date || null,
        
       
        poster_path: movie.poster_path 
          ? `https://image.tmdb.org/t/p/w500${movie.poster_path}` 
          : null,
          

        backdrop_path: movie.backdrop_path 
          ? `https://image.tmdb.org/t/p/w780${movie.backdrop_path}` 
          : null, 

        genre_ids: movie.genre_ids,
        popularity: movie.popularity,
        vote_average: movie.vote_average,
        vote_count: movie.vote_count
      }))

      const { error } = await supabase.from('movies').upsert(movies)

      if (error) {
        console.error(`Supabase error on page ${page}:`, error)
      } else {
        totalImported += movies.length
      }
    }

    return new Response(
      JSON.stringify({ message: `Success! Imported/Updated ${totalImported} movies.` }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.toString() }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    )
  }
})