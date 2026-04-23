'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Eye, Edit, Trash2, RefreshCw, ChevronLeft, ChevronRight, Search } from 'lucide-react';
import HouseholdDetails from '@/components/HouseholdDetails';
import EditHouseholdModal from '@/components/EditHouseholdModal';

export default function HouseholdsPage() {
  const [households, setHouseholds] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const pageSize = 100;

  // Modal States
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);

  const fetchHouseholds = useCallback(async () => {
    setLoading(true);
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = supabase
      .from('households')
      .select('*, residents(*)', { count: 'exact' })
      .eq('is_active', true)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (searchQuery) {
        query = query.or(`official_address.ilike.%${searchQuery}%,tuman_name.ilike.%${searchQuery}%,mfy_name.ilike.%${searchQuery}%`);
    }

    const { data, count } = await query;

    if (data) {
      setHouseholds(data);
      setTotal(count || 0);
    }
    setLoading(false);
  }, [page, searchQuery]);

  useEffect(() => {
    const timer = setTimeout(() => {
        fetchHouseholds();
    }, 400); // 400ms debounce
    return () => clearTimeout(timer);
  }, [fetchHouseholds]);

  const handleDelete = async (id: string) => {
    if (!confirm('Ushbu xonadonni va uning ichidagi barcha aholini bazadan butunlay o\'chirmoqchimisiz?')) return;
    
    setLoading(true);
    try {
      const { error } = await supabase
        .from('households')
        .delete()
        .eq('id', id);

      if (error) throw error;
      fetchHouseholds();
    } catch (err: any) {
      alert('Xatolik: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const totalPages = Math.ceil(total / pageSize);

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
            <h1 className="text-3xl font-bold tracking-tight text-white mb-1">Xonadonlar</h1>
            <p className="text-gray-500 text-sm">Barcha ro'yxatga olingan xonadonlar boshqaruvi</p>
        </div>
        
        <div className="flex items-center gap-3">
            <div className="relative group">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 group-focus-within:text-white transition-colors" />
                <input 
                    type="text" 
                    placeholder="Qidirish..." 
                    value={searchQuery}
                    onChange={(e) => { setSearchQuery(e.target.value); setPage(1); }}
                    className="bg-[#111] border border-white/10 rounded-lg pl-10 pr-4 py-2 text-sm focus:border-white/20 outline-none w-64"
                />
            </div>
            <button 
                onClick={fetchHouseholds}
                disabled={loading}
                className="p-2.5 bg-[#111] border border-white/10 rounded-lg hover:bg-white/5 transition-colors disabled:opacity-50"
            >
                <RefreshCw size={18} className={`${loading ? 'animate-spin' : ''}`} />
            </button>
            <div className="px-4 py-2 bg-white/5 border border-white/10 rounded-lg text-sm font-semibold">
                {total}
            </div>
        </div>
      </div>

      <div className="glass rounded-xl overflow-hidden border border-white/5">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-white/[0.02] text-gray-500 text-[11px] uppercase tracking-[0.1em] font-bold border-b border-white/5">
              <th className="px-6 py-4">ID</th>
              <th className="px-6 py-4">Manzil</th>
              <th className="px-6 py-4 text-center">Aholi</th>
              <th className="px-6 py-4 text-right">Amallar</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/[0.03]">
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                    <td className="px-6 py-5"><div className="h-4 bg-white/5 rounded w-8"></div></td>
                    <td className="px-6 py-5"><div className="h-4 bg-white/5 rounded w-64"></div></td>
                    <td className="px-6 py-5"><div className="h-4 bg-white/5 rounded w-12 mx-auto"></div></td>
                    <td className="px-6 py-5"><div className="h-4 bg-white/5 rounded w-20 ml-auto"></div></td>
                </tr>
              ))
            ) : households.map((h) => (
              <tr key={h.id} className="hover:bg-white/[0.02] transition-colors group">
                <td className="px-6 py-5 text-sm font-medium text-gray-500">#{h.id}</td>
                <td className="px-6 py-5">
                    <div className="text-sm text-gray-200 font-medium mb-0.5">{h.official_address}</div>
                    <div className="text-[11px] text-gray-600">{h.tuman_name} • {h.mfy_name}</div>
                </td>
                <td className="px-6 py-5 text-center">
                    <span className="text-sm font-mono text-[#0070f3] bg-[#0070f3]/10 px-2 py-0.5 rounded">
                        {h.residents?.length || 0}
                    </span>
                </td>
                <td className="px-6 py-5 text-right">
                  <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button 
                        onClick={() => { setSelectedItem(h); setIsDetailsOpen(true); }}
                        className="p-2 text-gray-400 hover:text-white hover:bg-white/5 rounded-lg transition-all"
                    >
                      <Eye size={16} />
                    </button>
                    <button 
                        onClick={() => { setSelectedItem(h); setIsEditOpen(true); }}
                        className="p-2 text-gray-400 hover:text-white hover:bg-white/5 rounded-lg transition-all"
                    >
                      <Edit size={16} />
                    </button>
                    <button 
                        onClick={() => handleDelete(h.id)}
                        className="p-2 text-red-900/50 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition-all"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        
        {/* Empty State */}
        {!loading && households.length === 0 && (
            <div className="py-20 text-center text-gray-600 text-sm italic">
                Ma'lumot topilmadi
            </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between py-4 border-t border-white/5">
            <p className="text-xs text-gray-500 font-medium">
                {total} ta yozuvdan { (page-1)*pageSize + 1 }-{ Math.min(page*pageSize, total) } oralig'i ko'rsatilmoqda
            </p>
            <div className="flex items-center gap-2">
                <button 
                    disabled={page === 1}
                    onClick={() => setPage(p => p - 1)}
                    className="p-2 bg-[#111] border border-white/10 rounded-lg hover:bg-white/5 disabled:opacity-20 transition-all"
                >
                    <ChevronLeft size={18} />
                </button>
                <div className="text-xs font-bold px-3 py-2 bg-white/5 border border-white/10 rounded-lg">
                    {page} / {totalPages}
                </div>
                <button 
                    disabled={page === totalPages}
                    onClick={() => setPage(p => p + 1)}
                    className="p-2 bg-[#111] border border-white/10 rounded-lg hover:bg-white/5 disabled:opacity-20 transition-all"
                >
                    <ChevronRight size={18} />
                </button>
            </div>
        </div>
      )}

      {/* Modals */}
      <HouseholdDetails 
        isOpen={isDetailsOpen} 
        onClose={() => setIsDetailsOpen(false)} 
        data={selectedItem} 
      />
      
      <EditHouseholdModal 
        isOpen={isEditOpen} 
        onClose={() => setIsEditOpen(false)} 
        data={selectedItem}
        onSaved={fetchHouseholds}
      />
    </div>
  );
}
