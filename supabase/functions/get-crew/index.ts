import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'

Deno.serve(async () => {
  const supabaseURL = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const tmdbApiKey = Deno.env.get('TMDB_API_KEY_READ')!

  const supabase = createClient(supabaseURL, serviceKey)

  const tmdbOptions = {
    headers: {
      Authorization: `Bearer ${tmdbApiKey}`,
      'Content-Type': 'application/json'
    }
  }

  const trendingRes = await fetch(
    'https://api.themoviedb.org/3/trending/person/week',
    tmdbOptions
  )

  if (!trendingRes.ok) {
    return new Response('TMDB trending error', { status: 500 })
  }

  const trending = await trendingRes.json()

  const people = trending.results.slice(0, 30)

  const peopleRows = people.map((p: any) => ({
    id: p.id,
    name: p.name,
    known_for_department: p.known_for_department,
    popularity: p.popularity,
    profile_path: p.profile_path
      ? `https://image.tmdb.org/t/p/w500${p.profile_path}`
      : null
  }))

  await supabase
    .from('people')
    .upsert(peopleRows, { onConflict: 'id' })

  let linkedMovies = 0

  for (const person of people) {
    const creditsRes = await fetch(
      `https://api.themoviedb.org/3/person/${person.id}/movie_credits`,
      tmdbOptions
    )

    if (!creditsRes.ok) continue

    const credits = await creditsRes.json()

    const allCredits = [
      ...(credits.cast || []).map((c: any) => ({
        movie_id: c.id,
        role: 'cast',
        character: c.character,
        order_index: c.order
      })),
      ...(credits.crew || []).map((c: any) => ({
        movie_id: c.id,
        role: 'crew',
        job: c.job
      }))
    ]

    if (!allCredits.length) continue

    const movieIds = [...new Set(allCredits.map(c => c.movie_id))]

    const { data: existingMovies } = await supabase
      .from('movies')
      .select('id')
      .in('id', movieIds)

    if (!existingMovies?.length) continue

    const existingIds = new Set(existingMovies.map(m => m.id))

    const links = allCredits
      .filter(c => existingIds.has(c.movie_id))
      .map(c => ({
        movie_id: c.movie_id,
        person_id: person.id,
        role: c.role,
        job: c.job ?? null,
        character: c.character ?? null,
        order_index: c.order_index ?? null
      }))

    if (!links.length) continue

    await supabase
      .from('movie_people')
      .upsert(links)

    linkedMovies += links.length
  }

  return new Response(
    JSON.stringify({
      message: 'Weekly trending people processed',
      people: people.length,
      linked_movies: linkedMovies
    }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
