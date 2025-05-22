import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'

Deno.serve(async (req) => {

  const supabaseURL = Deno.env.get('SUPABASE_URL') as string
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') as string

  const tdmbApiKey = Deno.env.get('TMDB_API_KEY')

  const supabase = createClient(supabaseURL, serviceKey)

  const searchParams = new URLSearchParams()
  searchParams.set('page', '1')
  searchParams.set('language', 'en-US') //język zwracanych danych

  // const tmdbResponce = await fetch(
  //   `https://api.themoviedb.org/3/discover/movie?${searchParams.toString()}`, 
  //   {
  //     method: 'GET',
  //     headers: {
  //       'Content-Type': 'application/json',
  //       Authorization: `Bearer ${tdmbApiKey}`,
  //     }
  //   }
  // )

  const tmdbResponce = await fetch(
    `https://api.themoviedb.org/3/trending/movie/week?${searchParams.toString()}`, 
    {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tdmbApiKey}`,
      }
    }
  )

  const tmdbJson = await tmdbResponce.json()

  const tmdbStatus = tmdbResponce.status
  if (!(200 <= tmdbStatus && tmdbStatus <= 299)) {
    throw new Error('Error retrieving data from tmdb API')
  }

  const movies: Movie[] = []

  for (const movie of tmdbJson.results){
    movies.push({
      id: movie.id,
      title: movie.title,
      description: movie.overview,
      release: movie.release_date,
      poster_path: movie.backdrop_path

    })
  }

  const { error } = await supabase.from('movies').upsert(movies)

  if (error) {
    throw new Error(`Error inserting data into supabase: ${error.message}`)
  }

  return new Response(
    "Done",
    { headers: { "Content-Type": "application/json" } },
  )
})

interface Movie {
  id: number
  title: string
  description: string
  release: string
  poster_path: string
  genres: string
}
