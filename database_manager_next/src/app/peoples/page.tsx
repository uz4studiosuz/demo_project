'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { 
  Users, Search, MoreVertical, Trash2, Edit2,
  ChevronLeft, ChevronRight, Phone, MapPin, 
  Loader2, RefreshCw, Home, ShieldCheck
} from 'lucide-react';
import EditResidentModal from '@/components/EditResidentModal';

export default function PeoplesPage() {
  const [peoples, setPeoples] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [pageSize] = useState(10);
  const [openDropdownId, setOpenDropdownId] = useState<string | null>(null);
  
  // Edit Modal State
  const [editingPerson, setEditingPerson] = useState<any>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  
  const [stats, setStats] = useState({
    residents: 0,
    households: 0,
    verified: 0
  });

  useEffect(() => {
    fetchData();
    fetchHeaderStats();
  }, [page, searchTerm]);

  useEffect(() => {
    const handleClickOutside = () => setOpenDropdownId(null);
    window.addEventListener('click', handleClickOutside);
    return () => window.removeEventListener('click', handleClickOutside);
  }, []);

  async function fetchHeaderStats() {
    try {
      const { count: rCount } = await supabase.from('residents').select('*', { count: 'exact', head: true }).eq('is_active', true);
      const { count: hCount } = await supabase.from('households').select('*', { count: 'exact', head: true }).eq('is_active', true);
      const { count: vCount } = await supabase.from('households').select('*', { count: 'exact', head: true }).eq('is_verified', true).eq('is_active', true);
      
      const vPercent = hCount ? Math.round((vCount! / hCount) * 100) : 0;
      
      setStats({
        residents: rCount || 0,
        households: hCount || 0,
        verified: vPercent
      });
    } catch (err) {
      console.error('Stats error:', err);
    }
  }

  async function fetchData() {
    setLoading(true);
    try {
      let query = supabase
        .from('residents')
        .select('*, households(official_address, house_number)', { count: 'exact' })
        .eq('is_active', true)
        .order('created_at', { ascending: false });

      if (searchTerm) {
        query = query.or(`first_name.ilike.%${searchTerm}%,last_name.ilike.%${searchTerm}%`);
      }

      const from = (page - 1) * pageSize;
      const to = from + pageSize - 1;

      const { data, count, error } = await query.range(from, to);

      if (error) throw error;
      setPeoples(data || []);
      setTotalCount(count || 0);
    } catch (err) {
      console.error('Error fetching peoples:', err);
    } finally {
      setLoading(false);
    }
  }

  const handleDeleteResident = async (id: string) => {
    if (!confirm('Ushbu fuqaroni bazadan butunlay o\'chirmoqchimisiz?')) return;
    
    // Haqiqiy o'chirish (delete)
    const { error } = await supabase
      .from('residents')
      .delete()
      .eq('id', id);

    if (error) {
      alert('O\'chirishda xatolik: ' + error.message);
    } else {
      fetchData();
      fetchHeaderStats();
    }
  };

  const handleEditClick = (person: any) => {
    setEditingPerson(person);
    setIsEditModalOpen(true);
    setOpenDropdownId(null);
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      {/* Header section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Aholi Ro'yxati</h1>
          <p className="text-gray-500 text-sm mt-1">Tizimdagi barcha ro'yxatga olingan fuqarolar ma'lumotlari</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => { setPage(1); fetchData(); fetchHeaderStats(); }}
            className="p-2.5 bg-[#171717] border border-white/5 rounded-xl text-gray-400 hover:text-white transition-all"
          >
            <RefreshCw size={20} />
          </button>
          <div className="relative group">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 group-focus-within:text-[#3ecf8e] transition-colors" size={18} />
            <input
              type="text"
              placeholder="Ism yoki familiya qidiruvi..."
              className="pl-10 pr-4 py-2.5 bg-[#171717] border border-white/5 rounded-xl focus:border-[#3ecf8e]/30 focus:ring-4 focus:ring-[#3ecf8e]/5 outline-none transition-all text-sm text-gray-200 min-w-[300px]"
              value={searchTerm}
              onChange={(e) => { setSearchTerm(e.target.value); setPage(1); }}
            />
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-[#171717] border border-white/5 p-6 rounded-2xl flex items-center gap-5 group hover:border-[#3ecf8e20] transition-all">
          <div className="w-14 h-14 bg-[#3ecf8e10] text-[#3ecf8e] rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform">
            <Users size={28} />
          </div>
          <div>
            <div className="text-2xl font-bold text-white">{stats.residents.toLocaleString()}</div>
            <div className="text-[10px] text-gray-500 uppercase font-bold tracking-widest mt-0.5">Jami Aholi</div>
          </div>
        </div>

        <div className="bg-[#171717] border border-white/5 p-6 rounded-2xl flex items-center gap-5 group hover:border-blue-500/20 transition-all">
          <div className="w-14 h-14 bg-blue-500/10 text-blue-500 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform">
            <Home size={28} />
          </div>
          <div>
            <div className="text-2xl font-bold text-white">{stats.households.toLocaleString()}</div>
            <div className="text-[10px] text-gray-500 uppercase font-bold tracking-widest mt-0.5">Xonadonlar</div>
          </div>
        </div>

        <div className="bg-[#171717] border border-white/5 p-6 rounded-2xl flex items-center gap-5 group hover:border-purple-500/20 transition-all">
          <div className="w-14 h-14 bg-purple-500/10 text-purple-500 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform">
            <ShieldCheck size={28} />
          </div>
          <div>
            <div className="text-2xl font-bold text-white">{stats.verified}%</div>
            <div className="text-[10px] text-gray-500 uppercase font-bold tracking-widest mt-0.5">Tasdiqlangan</div>
          </div>
        </div>
      </div>

      {/* Table Section */}
      <div className="bg-[#171717] border border-white/5 rounded-3xl overflow-hidden shadow-2xl relative">
        <div className="overflow-x-auto min-h-[400px]">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-white/[0.02] border-b border-white/5">
                <th className="px-6 py-5 text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em]">Fuqaro</th>
                <th className="px-6 py-5 text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em]">Manzil</th>
                <th className="px-6 py-5 text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em]">Telefon</th>
                <th className="px-6 py-5 text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em]">Jinsi</th>
                <th className="px-6 py-5 text-[10px] font-bold text-gray-500 uppercase tracking-[0.2em] text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={5} className="px-6 py-8"><div className="h-4 bg-white/5 rounded w-full"></div></td>
                  </tr>
                ))
              ) : peoples.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-20 text-center text-gray-500 italic">Ma'lumot topilmadi</td>
                </tr>
              ) : peoples.map((person) => (
                <tr key={person.id} className="hover:bg-white/[0.01] transition-colors group">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#3ecf8e] to-[#3ecf8e50] flex items-center justify-center text-black font-bold text-sm shadow-lg shadow-[#3ecf8e10]">
                        {person.first_name[0]}{person.last_name[0]}
                      </div>
                      <div>
                        <div className="font-bold text-white group-hover:text-[#3ecf8e] transition-colors">{person.first_name} {person.last_name}</div>
                        <div className="text-xs text-gray-500">{person.middle_name || '...'}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 text-sm text-gray-300">
                      <MapPin size={14} className="text-[#3ecf8e]" />
                      <span className="truncate max-w-[200px]">{person.households?.official_address || 'Noma\'lum'}</span>
                      <span className="text-gray-600">|</span>
                      <span className="text-xs font-bold text-gray-500 shrink-0">{person.households?.house_number}-uy</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 text-sm text-gray-400 font-mono">
                      <Phone size={14} />
                      {person.phone_primary || 'Yo\'q'}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      person.gender === 'MALE' ? 'bg-blue-500/10 text-blue-500 border border-blue-500/10' : 
                      person.gender === 'FEMALE' ? 'bg-pink-500/10 text-pink-500 border border-pink-500/10' : 
                      'bg-gray-500/10 text-gray-500'
                    }`}>
                      {person.gender === 'MALE' ? 'Erkak' : person.gender === 'FEMALE' ? 'Ayol' : 'Noma\'lum'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right relative">
                    <button 
                      onClick={(e) => {
                        e.stopPropagation();
                        setOpenDropdownId(openDropdownId === person.id ? null : person.id);
                      }}
                      className={`p-2 rounded-lg transition-all ${openDropdownId === person.id ? 'bg-[#3ecf8e] text-black' : 'text-gray-600 hover:text-white hover:bg-white/5'}`}
                    >
                      <MoreVertical size={18} />
                    </button>

                    {/* Dropdown Menu */}
                    {openDropdownId === person.id && (
                      <div className="absolute right-6 top-14 w-40 bg-[#1c1c1c] border border-white/5 rounded-xl shadow-2xl z-50 py-2 animate-in fade-in zoom-in-95 duration-150">
                        <button 
                          onClick={() => handleEditClick(person)}
                          className="w-full px-4 py-2 text-left text-sm text-gray-300 hover:bg-white/5 hover:text-[#3ecf8e] flex items-center gap-2 transition-colors"
                        >
                          <Edit2 size={14} />
                          Tahrirlash
                        </button>
                        <div className="h-px bg-white/5 my-1 mx-2"></div>
                        <button 
                          onClick={() => handleDeleteResident(person.id)}
                          className="w-full px-4 py-2 text-left text-sm text-red-500 hover:bg-red-500/10 flex items-center gap-2 transition-colors"
                        >
                          <Trash2 size={14} />
                          O'chirish
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="px-6 py-4 border-t border-white/5 flex items-center justify-between bg-white/[0.01]">
          <div className="text-xs text-gray-500">
            Jami <span className="text-white font-bold">{totalCount}</span> tadan 
            <span className="text-white font-bold ml-1">{(page - 1) * pageSize + 1} - {Math.min(page * pageSize, totalCount)}</span> ko'rsatilmoqda
          </div>
          <div className="flex items-center gap-2">
            <button 
              disabled={page === 1}
              onClick={() => setPage(p => p - 1)}
              className="p-2 bg-white/5 rounded-lg text-gray-400 hover:text-white disabled:opacity-20 transition-all"
            >
              <ChevronLeft size={20} />
            </button>
            <div className="text-sm text-white font-bold px-3 py-1 bg-[#3ecf8e20] text-[#3ecf8e] rounded-md border border-[#3ecf8e10]">
              {page}
            </div>
            <button 
              disabled={page * pageSize >= totalCount}
              onClick={() => setPage(p => p + 1)}
              className="p-2 bg-white/5 rounded-lg text-gray-400 hover:text-white disabled:opacity-20 transition-all"
            >
              <ChevronRight size={20} />
            </button>
          </div>
        </div>
      </div>

      {/* Edit Resident Modal */}
      <EditResidentModal 
        person={editingPerson}
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        onSuccess={() => {
          fetchData();
          fetchHeaderStats();
        }}
      />
    </div>
  );
}
