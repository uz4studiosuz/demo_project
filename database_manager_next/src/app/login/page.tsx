'use client';

import React, { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';
import { Database, Lock, User, Loader2, AlertCircle } from 'lucide-react';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const router = useRouter();

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Custom table check (app_users)
      const { data: user, error: dbError } = await supabase
        .from('app_users')
        .select('*')
        .eq('username', username)
        .eq('password_hash', password)
        .eq('role', 'ADMIN')
        .eq('is_active', true)
        .single();

      if (dbError || !user) {
        throw new Error('Foydalanuvchi nomi yoki parol xato, yoki sizda ADMIN huquqi yo\'q.');
      }

      // Store "session" in Cookie (so middleware can read it)
      document.cookie = `admin_session=${user.id}; path=/; max-age=86400`; // 24 hours
      localStorage.setItem('admin_user', JSON.stringify(user));
      
      // Also try to sign in to Supabase Auth if needed, but for now we'll just redirect
      router.push('/');
    } catch (err: any) {
      setError(err.message || 'Xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-[#1c1c1c] flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-[#3ecf8e] text-black rounded-2xl mb-6 shadow-lg shadow-[#3ecf8e]/20">
            <Database size={32} />
          </div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Admin Dashboard</h1>
          <p className="text-gray-500 mt-2 text-sm">Tizimga kirish uchun ADMIN hisobi talab qilinadi</p>
        </div>

        <div className="bg-[#171717] border border-white/5 p-8 rounded-3xl shadow-2xl">
          <form onSubmit={handleLogin} className="space-y-6">
            {error && (
              <div className="bg-red-500/10 border border-red-500/20 text-red-500 p-4 rounded-xl text-sm flex items-start gap-3">
                <AlertCircle size={18} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <div className="space-y-2">
              <label className="text-xs font-bold text-gray-500 uppercase tracking-widest ml-1">Foydalanuvchi nomi</label>
              <div className="relative">
                <User size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-600" />
                <input
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full bg-[#111] border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#3ecf8e]/50 focus:ring-4 focus:ring-[#3ecf8e]/10 outline-none transition-all text-sm"
                  placeholder="Masalan: surveyor1"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-bold text-gray-500 uppercase tracking-widest ml-1">Maxfiy parol</label>
              <div className="relative">
                <Lock size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-600" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-[#111] border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#3ecf8e]/50 focus:ring-4 focus:ring-[#3ecf8e]/10 outline-none transition-all"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#3ecf8e] text-black font-bold py-3 rounded-xl hover:bg-[#34b27b] active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {loading ? (
                <Loader2 className="animate-spin" size={20} />
              ) : (
                'Kirish'
              )}
            </button>
          </form>
        </div>

        <p className="text-center text-xs text-gray-600">
          Agar profilingizda ADMIN roli bo'lmasa, tizimga kirish bloklanadi.
        </p>
      </div>
    </div>
  );
}
