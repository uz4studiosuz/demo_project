'use client';

import React, { useState, useEffect } from 'react';
import { X, Save, Loader2 } from 'lucide-react';
import { supabase } from '@/lib/supabase';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: any;
  onSaved: () => void;
}

const EditHouseholdModal = ({ isOpen, onClose, data, onSaved }: Props) => {
  const [formData, setFormData] = useState<any>({});
  const [districts, setDistricts] = useState<any[]>([]);
  const [neighborhoods, setNeighborhoods] = useState<any[]>([]);
  const [streets, setStreets] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [initLoading, setInitLoading] = useState(false);

  useEffect(() => {
    if (isOpen && data) {
      setFormData(data);
      initializeData();
    }
  }, [isOpen, data]);

  async function initializeData() {
    setInitLoading(true);
    const { data: dData } = await supabase.from('districts').select('*').order('name');
    if (dData) setDistricts(dData);

    const district = dData?.find(d => d.name === data.tuman_name);
    if (district) {
      const { data: nData } = await supabase.from('neighborhoods').select('*').eq('district_id', district.id).order('name');
      if (nData) {
        setNeighborhoods(nData);
        const neighborhood = nData.find(n => n.name === data.mfy_name);
        if (neighborhood) {
          const { data: sData } = await supabase.from('streets').select('*').eq('neighborhood_id', neighborhood.id).order('name');
          if (sData) setStreets(sData);
        }
      }
    }
    setInitLoading(false);
  }

  async function handleDistrictChange(name: string) {
    const district = districts.find(d => d.name === name);
    setFormData({ ...formData, tuman_name: name, mfy_name: '', street_name: '' });
    if (district) {
      const { data: nData } = await supabase.from('neighborhoods').select('*').eq('district_id', district.id).order('name');
      setNeighborhoods(nData || []);
      setStreets([]);
    }
  }

  async function handleNeighborhoodChange(name: string) {
    const neighborhood = neighborhoods.find(n => n.name === name);
    setFormData({ ...formData, mfy_name: name, street_name: '' });
    if (neighborhood) {
      const { data: sData } = await supabase.from('streets').select('*').eq('neighborhood_id', neighborhood.id).order('name');
      setStreets(sData || []);
    }
  }

  function updatePreview(newFields: any) {
    const combined = { ...formData, ...newFields };
    let preview = "Farg'ona viloyati";
    if (combined.tuman_name) preview += `, ${combined.tuman_name}`;
    if (combined.mfy_name) preview += `, ${combined.mfy_name}`;
    if (combined.street_name) preview += `, ${combined.street_name}`;
    if (combined.house_number) preview += `, ${combined.house_number}-uy`;
    
    setFormData({ ...combined, official_address: preview });
  }

  async function handleSave() {
    setLoading(true);
    const { error } = await supabase
      .from('households')
      .update({
        tuman_name: formData.tuman_name,
        mfy_name: formData.mfy_name,
        street_name: formData.street_name,
        house_number: formData.house_number,
        official_address: formData.official_address
      })
      .eq('id', data.id);

    if (!error) {
      onSaved();
      onClose();
    }
    setLoading(false);
  }

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
      <div className="bg-[#0a0a0a] border border-white/10 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl animate-in fade-in slide-in-from-bottom-4 duration-300">
        <div className="px-6 py-5 border-b border-white/5 flex justify-between items-center bg-white/[0.02]">
          <h3 className="font-bold text-white tracking-tight">Ma'lumotni tahrirlash</h3>
          <button onClick={onClose} className="p-1 hover:bg-white/5 rounded-full transition-colors text-gray-500 hover:text-white">
            <X size={20} />
          </button>
        </div>

        <div className="p-6 space-y-5">
          {initLoading ? (
             <div className="py-10 text-center text-gray-500 flex flex-col items-center gap-3">
                <Loader2 className="animate-spin text-[#0070f3]" />
                <span className="text-sm font-medium">Baza bilan bog'lanilmoqda...</span>
             </div>
          ) : (
            <>
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.1em]">Tuman / Shahar</label>
                <select 
                  value={formData.tuman_name} 
                  onChange={(e) => handleDistrictChange(e.target.value)}
                  className="w-full p-3 bg-white/[0.03] border border-white/10 rounded-xl focus:border-[#0070f3]/50 focus:ring-4 focus:ring-[#0070f3]/10 outline-none transition-all text-sm text-gray-200"
                >
                  <option value="" className="bg-black">Tanlang...</option>
                  {districts.map(d => <option key={d.id} value={d.name} className="bg-black">{d.name}</option>)}
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.1em]">MFY (Mahalla)</label>
                <select 
                  value={formData.mfy_name} 
                  onChange={(e) => handleNeighborhoodChange(e.target.value)}
                  className="w-full p-3 bg-white/[0.03] border border-white/10 rounded-xl focus:border-[#0070f3]/50 focus:ring-4 focus:ring-[#0070f3]/10 outline-none transition-all text-sm text-gray-200"
                >
                  <option value="" className="bg-black">Tanlang...</option>
                  {neighborhoods.map(n => <option key={n.id} value={n.name} className="bg-black">{n.name}</option>)}
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.1em]">Ko'cha</label>
                <select 
                  value={formData.street_name} 
                  onChange={(e) => {
                    const val = e.target.value;
                    updatePreview({ street_name: val });
                  }}
                  className="w-full p-3 bg-white/[0.03] border border-white/10 rounded-xl focus:border-[#0070f3]/50 focus:ring-4 focus:ring-[#0070f3]/10 outline-none transition-all text-sm text-gray-200"
                >
                  <option value="" className="bg-black">Tanlang...</option>
                  {streets.map(s => <option key={s.id} value={s.name} className="bg-black">{s.name}</option>)}
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.1em]">Uy raqami</label>
                <input 
                  type="text" 
                  value={formData.house_number || ''} 
                  onChange={(e) => updatePreview({ house_number: e.target.value })}
                  className="w-full p-3 bg-white/[0.03] border border-white/10 rounded-xl focus:border-[#0070f3]/50 focus:ring-4 focus:ring-[#0070f3]/10 outline-none transition-all text-sm text-gray-200"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-[0.1em]">Rasmiy manzil (Preview)</label>
                <textarea 
                  value={formData.official_address} 
                  readOnly 
                  rows={2}
                  className="w-full p-3 bg-white/[0.01] border border-white/5 rounded-xl text-gray-600 text-xs cursor-not-allowed outline-none"
                />
              </div>
            </>
          )}
        </div>

        <div className="px-6 py-4 bg-white/[0.02] border-t border-white/5 flex gap-3 justify-end">
          <button 
            onClick={onClose}
            className="px-5 py-2 rounded-lg text-xs font-bold text-gray-500 hover:text-white hover:bg-white/5 transition-all"
          >
            Bekor qilish
          </button>
          <button 
            onClick={handleSave}
            disabled={loading || initLoading}
            className="flex items-center gap-2 bg-[#0070f3] text-white px-8 py-2 rounded-lg text-xs font-bold hover:bg-[#0070f3]/90 transition-all disabled:opacity-50 shadow-lg shadow-[#0070f3]/20"
          >
            {loading ? <Loader2 className="animate-spin" size={16} /> : <Save size={16} />}
            Saqlash
          </button>
        </div>
      </div>
    </div>
  );
};

export default EditHouseholdModal;
