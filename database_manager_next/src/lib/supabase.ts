import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://buxmevplyaxrsueclbks.supabase.co';
const SUPABASE_KEY = 'sb_publishable_S5xhUUjaxhMZXF87v3GG6A_-QhbO77c';

export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
