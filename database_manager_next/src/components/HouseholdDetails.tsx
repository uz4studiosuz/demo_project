'use client';

import React from 'react';
import { X, MapPin, ExternalLink, Users } from 'lucide-react';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  data: any;
}

const HouseholdDetails = ({ isOpen, onClose, data }: Props) => {
  if (!isOpen || !data) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
      <div className="bg-[#0a0a0a] border border-white/10 rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl animate-in fade-in zoom-in duration-200">
        <div className="px-8 py-6 border-b border-white/5 flex justify-between items-center bg-white/[0.02]">
          <h3 className="text-xl font-bold text-white tracking-tight">Xonadon tafsilotlari</h3>
          <button onClick={onClose} className="p-2 hover:bg-white/5 rounded-full transition-colors text-gray-500 hover:text-white">
            <X size={20} />
          </button>
        </div>

        <div className="p-8">
          <div className="grid grid-cols-2 gap-4 mb-8">
            <DetailItem label="ID" value={`#${data.id}`} />
            <DetailItem label="Mulk turi" value={data.property_type === 'HOUSE' ? 'Hovli' : 'Kvartira'} />
            <DetailItem label="Tuman / Shahar" value={data.tuman_name} />
            <DetailItem label="MFY (Mahalla)" value={data.mfy_name} />
            <DetailItem label="Ko'cha" value={data.street_name || 'Noma\'lum'} />
            <DetailItem label="Uy raqami" value={data.house_number || 'Noma\'lum'} />
            <div className="col-span-2">
                <DetailItem label="Rasmiy to'liq manzil" value={data.official_address} />
            </div>
            <div className="col-span-2 bg-[#0070f3]/10 border border-[#0070f3]/20 p-4 rounded-xl flex justify-between items-center">
                <div>
                    <div className="text-[10px] uppercase font-bold text-[#0070f3] tracking-wider mb-1">Koordinatalar</div>
                    <div className="text-sm font-medium text-gray-300">{data.latitude}, {data.longitude}</div>
                </div>
                <button 
                    onClick={() => window.open(`https://www.google.com/maps/search/?api=1&query=${data.latitude},${data.longitude}`, '_blank')}
                    className="flex items-center gap-2 bg-[#0070f3] text-white px-4 py-2 rounded-lg text-xs font-bold hover:bg-[#0070f3]/90 transition-all shadow-lg shadow-[#0070f3]/20"
                >
                    <ExternalLink size={16} />
                    Google Maps
                </button>
            </div>
          </div>

          <div>
            <div className="flex items-center gap-2 mb-4 text-white font-bold text-sm tracking-tight">
                <Users size={16} className="text-[#0070f3]" />
                <span>Aholi ro'yxati ({data.residents?.length || 0} nafar)</span>
            </div>
            <div className="space-y-1.5 max-h-[180px] overflow-y-auto pr-2 custom-scrollbar">
                {data.residents?.map((r: any) => (
                    <div key={r.id} className="flex justify-between items-center p-3 bg-white/[0.02] rounded-xl border border-white/5 hover:border-white/10 transition-colors">
                        <span className="text-sm font-medium text-gray-300">{r.last_name} {r.first_name}</span>
                        <span className="text-[10px] font-bold text-gray-600 uppercase tracking-widest">{r.role || 'A\'zo'}</span>
                    </div>
                ))}
                {(!data.residents || data.residents.length === 0) && (
                    <div className="text-center py-4 text-gray-600 italic text-sm">Aholi ma'lumotlari mavjud emas</div>
                )}
            </div>
          </div>
        </div>

        <div className="px-8 py-4 bg-white/[0.02] border-t border-white/5 flex justify-end">
            <button onClick={onClose} className="px-6 py-2 bg-white/5 border border-white/10 rounded-lg text-xs font-bold text-gray-400 hover:text-white hover:bg-white/10 transition-colors">
                Yopish
            </button>
        </div>
      </div>
    </div>
  );
};

function DetailItem({ label, value }: { label: string; value: string }) {
    return (
        <div className="bg-white/[0.02] p-4 rounded-xl border border-white/5">
            <div className="text-[10px] uppercase font-bold text-gray-600 tracking-wider mb-1">{label}</div>
            <div className="text-sm font-semibold text-gray-300 leading-relaxed">{value}</div>
        </div>
    );
}

export default HouseholdDetails;
