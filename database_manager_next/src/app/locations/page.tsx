'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { 
  MapPin, Plus, Edit2, Trash2, Search, Map as MapIcon, 
  Home, ChevronRight, ChevronLeft, Building2, LayoutGrid, AlertCircle, Building
} from 'lucide-react';

type ViewMode = 'districts' | 'neighborhoods' | 'streets';

export default function LocationsPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('districts');
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Selection state
  const [selectedDistrict, setSelectedDistrict] = useState<any>(null);
  const [selectedNeighborhood, setSelectedNeighborhood] = useState<any>(null);

  // Modal state
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState<any>(null);
  const [itemName, setItemName] = useState('');
  const [isCity, setIsCity] = useState(false);

  useEffect(() => {
    fetchData();
  }, [viewMode, selectedDistrict, selectedNeighborhood]);

  async function fetchData() {
    setLoading(true);
    try {
      if (viewMode === 'districts') {
        const { data: districts } = await supabase.from('districts').select('*').order('name');
        const { data: mfys } = await supabase.from('neighborhoods').select('district_id');
        const enhanced = (districts || []).map(d => ({
          ...d,
          count: (mfys || []).filter(m => m.district_id === d.id).length
        }));
        setData(enhanced);
      } 
      else if (viewMode === 'neighborhoods' && selectedDistrict) {
        const { data: mfys } = await supabase.from('neighborhoods').select('*').eq('district_id', selectedDistrict.id).order('name');
        const { data: streets } = await supabase.from('streets').select('neighborhood_id');
        const enhanced = (mfys || []).map(m => ({
          ...m,
          count: (streets || []).filter(s => s.neighborhood_id === m.id).length
        }));
        setData(enhanced);
      } 
      else if (viewMode === 'streets' && selectedNeighborhood) {
        const { data: streets } = await supabase.from('streets').select('*').eq('neighborhood_id', selectedNeighborhood.id).order('name');
        setData(streets || []);
      }
    } catch (err) {
      console.error('Fetch error:', err);
    } finally {
      setLoading(false);
    }
  }

  const handleSave = async () => {
    if (!itemName) return;
    
    let finalName = itemName.trim();
    const payload: any = { name: finalName };

    if (viewMode === 'districts') {
      // Clean previous suffixes
      finalName = finalName.replace(/\stumani$/g, '').replace(/\ssh\.$/g, '');
      finalName = isCity ? `${finalName} sh.` : `${finalName} tumani`;
      payload.name = finalName;
      payload.is_city = isCity;
    }

    if (viewMode === 'neighborhoods') payload.district_id = selectedDistrict.id;
    if (viewMode === 'streets') payload.neighborhood_id = selectedNeighborhood.id;

    let error;
    if (editingItem) {
      const { error: err } = await supabase.from(viewMode).update(payload).eq('id', editingItem.id);
      error = err;
    } else {
      const { error: err } = await supabase.from(viewMode).insert([payload]);
      error = err;
    }

    if (!error) {
      setShowModal(false);
      setItemName('');
      setIsCity(false);
      setEditingItem(null);
      fetchData();
    } else {
      alert('Xatolik: ' + error.message);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Haqiqatdan ham o\'chirmoqchimisiz?')) return;
    const { error } = await supabase.from(viewMode).delete().eq('id', id);
    if (!error) fetchData();
  };

  const navigateBack = () => {
    if (viewMode === 'streets') {
      setViewMode('neighborhoods');
      setSelectedNeighborhood(null);
    } else if (viewMode === 'neighborhoods') {
      setViewMode('districts');
      setSelectedDistrict(null);
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      {/* Header & Breadcrumbs */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
            <button onClick={() => { setViewMode('districts'); setSelectedDistrict(null); setSelectedNeighborhood(null); }} className="hover:text-white transition-colors">Hududlar</button>
            {selectedDistrict && (
              <>
                <ChevronRight size={14} />
                <button onClick={() => { setViewMode('neighborhoods'); setSelectedNeighborhood(null); }} className="hover:text-white transition-colors">{selectedDistrict.name}</button>
              </>
            )}
            {selectedNeighborhood && (
              <>
                <ChevronRight size={14} />
                <span className="text-[#3ecf8e] font-bold">{selectedNeighborhood.name}</span>
              </>
            )}
          </div>
          <h1 className="text-3xl font-bold text-white tracking-tight">
            {viewMode === 'districts' ? 'Tumanlar / Shaharlar' : viewMode === 'neighborhoods' ? 'MFYlar' : 'Ko\'chalar'}
          </h1>
        </div>
        
        <button 
          onClick={() => { setShowModal(true); setEditingItem(null); setItemName(''); setIsCity(false); }}
          className="flex items-center gap-2 px-5 py-2.5 bg-[#3ecf8e] text-black rounded-xl hover:bg-[#3ecf8e]/90 transition-all font-bold"
        >
          <Plus size={20} />
          {viewMode === 'districts' ? 'Tuman qo\'shish' : viewMode === 'neighborhoods' ? 'MFY qo\'shish' : 'Ko\'cha qo\'shish'}
        </button>
      </div>

      {/* Grid List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          Array(6).fill(0).map((_, i) => (
            <div key={i} className="h-32 bg-[#171717] border border-white/5 rounded-2xl animate-pulse"></div>
          ))
        ) : data.length === 0 ? (
          <div className="col-span-full py-20 text-center bg-[#171717] border border-dashed border-white/10 rounded-3xl">
            <LayoutGrid className="mx-auto text-gray-700 mb-4" size={48} />
            <p className="text-gray-500 italic">Hali ma'lumot kiritilmagan</p>
          </div>
        ) : data.map((item) => (
          <div 
            key={item.id} 
            className="group relative bg-[#171717] border border-white/5 p-6 rounded-2xl hover:border-[#3ecf8e]/30 transition-all cursor-pointer"
            onClick={() => {
              if (viewMode === 'districts') {
                setSelectedDistrict(item);
                setViewMode('neighborhoods');
              } else if (viewMode === 'neighborhoods') {
                setSelectedNeighborhood(item);
                setViewMode('streets');
              }
            }}
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-4">
                <div className={`w-12 h-12 bg-white/5 rounded-xl flex items-center justify-center transition-all ${item.is_city ? 'text-blue-400 group-hover:bg-blue-400 group-hover:text-black' : 'text-[#3ecf8e] group-hover:bg-[#3ecf8e] group-hover:text-black'}`}>
                  {viewMode === 'districts' ? (item.is_city ? <Building size={24} /> : <MapIcon size={24} />) : viewMode === 'neighborhoods' ? <Building2 size={24} /> : <Home size={24} />}
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white group-hover:text-[#3ecf8e] transition-colors">{item.name}</h3>
                  <p className="text-xs text-gray-500 uppercase tracking-widest font-bold">
                    {viewMode === 'districts' ? (item.is_city ? 'Shahar' : 'Tuman') : viewMode === 'neighborhoods' ? 'MFY' : 'Ko\'cha'}
                  </p>
                </div>
              </div>
              
              <div className="flex gap-1" onClick={(e) => e.stopPropagation()}>
                <button 
                  onClick={() => { 
                    setEditingItem(item); 
                    setItemName(item.name.replace(/\stumani$/g, '').replace(/\ssh\.$/g, '')); 
                    setIsCity(item.is_city || false);
                    setShowModal(true); 
                  }}
                  className="p-2 text-gray-600 hover:text-white transition-colors"
                >
                  <Edit2 size={16} />
                </button>
                <button 
                  onClick={() => handleDelete(item.id)}
                  className="p-2 text-gray-600 hover:text-red-500 transition-colors"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
            
            <div className="mt-6 flex items-center justify-between">
              {viewMode !== 'streets' ? (
                <div className="flex items-center gap-2">
                   <span className="px-2 py-0.5 bg-[#3ecf8e10] text-[#3ecf8e] text-[10px] font-bold rounded-md border border-[#3ecf8e10]">
                     {item.count || 0} {viewMode === 'districts' ? 'MFY' : 'Ko\'cha'}
                   </span>
                </div>
              ) : (
                <div className="h-4"></div>
              )}
              {viewMode !== 'streets' && (
                <ChevronRight size={14} className="text-gray-600 group-hover:text-[#3ecf8e] group-hover:translate-x-1 transition-all" />
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Back Button */}
      {viewMode !== 'districts' && (
        <button 
          onClick={navigateBack}
          className="flex items-center gap-2 text-gray-500 hover:text-white transition-all text-sm font-bold mt-10"
        >
          <ChevronLeft size={18} />
          Ortga qaytish
        </button>
      )}

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm" onClick={() => setShowModal(false)}></div>
          <div className="bg-[#171717] border border-white/5 w-full max-w-md rounded-3xl p-8 relative z-50 animate-in zoom-in-95 duration-200">
            <h2 className="text-xl font-bold text-white mb-2">{editingItem ? 'Tahrirlash' : 'Yangi qo\'shish'}</h2>
            <p className="text-xs text-gray-500 mb-6 uppercase tracking-widest font-bold">
              {viewMode === 'districts' ? 'Bosh hudud' : viewMode === 'neighborhoods' ? `${selectedDistrict?.name} ichiga` : `${selectedNeighborhood?.name} ichiga`}
            </p>
            
            <div className="space-y-6">
              {viewMode === 'districts' && (
                <div className="flex p-1 bg-[#111] border border-white/10 rounded-xl">
                   <button 
                    onClick={() => setIsCity(false)}
                    className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all ${!isCity ? 'bg-[#3ecf8e] text-black' : 'text-gray-500'}`}
                   >
                     Tuman
                   </button>
                   <button 
                    onClick={() => setIsCity(true)}
                    className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all ${isCity ? 'bg-blue-500 text-white' : 'text-gray-500'}`}
                   >
                     Shahar
                   </button>
                </div>
              )}

              <div>
                <label className="block text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-2">Nomi</label>
                <input
                  type="text"
                  autoFocus
                  className="w-full bg-[#111] border border-white/10 rounded-xl py-4 px-5 text-white outline-none focus:border-[#3ecf8e]/30 transition-all"
                  placeholder="Masalan: Farg'ona"
                  value={itemName}
                  onChange={(e) => setItemName(e.target.value)}
                />
                {viewMode === 'districts' && (
                  <p className="text-[10px] text-gray-600 mt-2 italic">
                    Avtomatik ravishda <span className="text-white font-bold">{itemName} {isCity ? 'sh.' : 'tumani'}</span> ko'rinishida saqlanadi.
                  </p>
                )}
              </div>
            </div>

            <div className="mt-8 flex gap-3">
              <button onClick={() => setShowModal(false)} className="flex-1 px-4 py-3 bg-white/5 text-gray-400 rounded-xl hover:bg-white/10 transition-all font-bold">Bekor qilish</button>
              <button onClick={handleSave} className="flex-1 px-4 py-3 bg-[#3ecf8e] text-black rounded-xl hover:bg-[#3ecf8e]/90 transition-all font-bold">Saqlash</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
