import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing environment variables')
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const cutoffTime = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()

    console.log(`Deleting groups created before: ${cutoffTime}`)

    const { data: deletedGroups, error } = await supabase
      .from('groups')
      .delete()
      .lt('created_at', cutoffTime)
      .select('id, created_at')

    if (error) {
      console.error('Error deleting groups:', error)
      throw error
    }

    const deletedCount = deletedGroups?.length || 0
    console.log(`Successfully deleted ${deletedCount} groups`)

    return new Response(
      JSON.stringify({
        success: true,
        deleted_count: deletedCount,
        deleted_groups: deletedGroups,
        cutoff_time: cutoffTime,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})