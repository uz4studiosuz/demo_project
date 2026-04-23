'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { X, User, Phone, Info, Save, Loader2 } from 'lucide-react';

interface EditResidentModalProps {
  person: any;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function EditResidentModal({ person, isOpen, onClose, onSuccess }: EditResidentModalProps) {
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    middle_name: '',
    phone_primary: '',
    gender: 'UNKNOWN'
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (person) {
      setFormData({
        first_name: person.first_name || '',
        last_name: person.last_name || '',
        middle_name: person.middle_name || '',
        phone_primary: person.phone_primary || '',
        gender: person.gender || 'UNKNOWN'
      });
    }
  }, [person]);

  const handleSave = async () => {
    setLoading(true);
    try {
      const { error } = await supabase
        .from('residents')
        .update(formData)
        .eq('id', person.id);

      if (error) throw error;
      onSuccess();
      onClose();
    } catch (err: any) {
      alert('Xatolik: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <div className="fixed inset-0 bg-black/80 backdrop-blur-md" onClick={onClose}></div>
      <div className="bg-[#171717] border border-white/10 w-full max-w-lg rounded-[2rem] overflow-hidden relative z-[101] shadow-2xl animate-in zoom-in-95 duration-200">
        <div className="p-8">
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-[#3ecf8e10] text-[#3ecf8e] rounded-xl flex items-center justify-center">
                <Edit2 size={20} />
              </div>
              <div>
                <h2 className="text-xl font-bold text-white">Tahrirlash</h2>
                <p className="text-xs text-gray-500 uppercase tracking-widest font-bold">Fuqaro ma'lumotlari</p>
              </div>
            </div>
            <button onClick={onClose} className="p-2 text-gray-500 hover:text-white hover:bg-white/5 rounded-full transition-all">
              <X size={20} />
            </button>
          </div>

          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest ml-1">Ismi</label>
                <div className="relative">
                  <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-600" size={16} />
                  <input
                    type="text"
                    className="w-full bg-[#111] border border-white/5 rounded-2xl py-4 pl-12 pr-4 text-white outline-none focus:border-[#3ecf8e]/30 transition-all text-sm"
                    value={formData.first_name}
                    onChange={(e) => setFormData({...formData, first_name: e.target.value})}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest ml-1">Familiyasi</label>
                <input
                  type="text"
                  className="w-full bg-[#111] border border-white/5 rounded-2xl py-4 px-5 text-white outline-none focus:border-[#3ecf8e]/30 transition-all text-sm"
                  value={formData.last_name}
                  onChange={(e) => setFormData({...formData, last_name: e.target.value})}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest ml-1">Otasining ismi</label>
              <input
                type="text"
                className="w-full bg-[#111] border border-white/5 rounded-2xl py-4 px-5 text-white outline-none focus:border-[#3ecf8e]/30 transition-all text-sm"
                value={formData.middle_name}
                onChange={(e) => setFormData({...formData, middle_name: e.target.value})}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest ml-1">Telefon</label>
                <div className="relative">
                  <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-600" size={16} />
                  <input
                    type="text"
                    className="w-full bg-[#111] border border-white/5 rounded-2xl py-4 pl-12 pr-4 text-white outline-none focus:border-[#3ecf8e]/30 transition-all text-sm"
                    value={formData.phone_primary}
                    onChange={(e) => setFormData({...formData, phone_primary: e.target.value})}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest ml-1">Jinsi</label>
                <select
                  className="w-full bg-[#111] border border-white/5 rounded-2xl py-4 px-5 text-white outline-none focus:border-[#3ecf8e]/30 transition-all text-sm"
                  value={formData.gender}
                  onChange={(e) => setFormData({...formData, gender: e.target.value})}
                >
                  <option value="MALE">Erkak</option>
                  <option value="FEMALE">Ayol</option>
                  <option value="UNKNOWN">Noma'lum</option>
                </select>
              </div>
            </div>
          </div>

          <div className="mt-10 flex gap-4">
            <button 
              onClick={onClose}
              className="flex-1 py-4 bg-white/5 text-gray-400 rounded-2xl font-bold hover:bg-white/10 transition-all text-sm"
            >
              Bekor qilish
            </button>
            <button 
              onClick={handleSave}
              disabled={loading}
              className="flex-1 py-4 bg-[#3ecf8e] text-black rounded-2xl font-bold hover:bg-[#3ecf8e]/90 transition-all text-sm flex items-center justify-center gap-2"
            >
              {loading ? <Loader2 className="animate-spin" size={18} /> : <Save size={18} />}
              Saqlash
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// Internal Edit2 icon for the modal header
function Edit2({ size }: { size: number }) {
  return (
    <svg 
      width={size} height={size} viewBox="0 0 24 24" fill="none" 
      stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
    >
      <path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z" />
    </svg>
  );
}
