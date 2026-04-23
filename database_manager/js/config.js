const CONFIG = {
    SUPABASE_URL: 'https://buxmevplyaxrsueclbks.supabase.co',
    SUPABASE_KEY: 'sb_publishable_S5xhUUjaxhMZXF87v3GG6A_-QhbO77c',
    PAGE_SIZE: 100
};

// Initialize Supabase Client
const client = supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_KEY);
