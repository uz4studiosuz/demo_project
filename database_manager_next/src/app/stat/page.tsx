'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { Bar, Pie, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  PointElement,
  LineElement,
} from 'chart.js';
import { Users, Home, TrendingUp, ShieldCheck, MapPin, Activity, Loader2, RefreshCw } from 'lucide-react';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

export default function StatPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  async function fetchStats() {
    setLoading(true);
    try {
      // 1. Basic Counts
      const { count: hCount } = await supabase.from('households').select('*', { count: 'exact', head: true }).eq('is_active', true);
      const { count: rCount } = await supabase.from('residents').select('*', { count: 'exact', head: true }).eq('is_active', true);
      const { count: dCount } = await supabase.from('districts').select('*', { count: 'exact', head: true });
      const { count: vCount } = await supabase.from('households').select('*', { count: 'exact', head: true }).eq('is_verified', true).eq('is_active', true);

      // 2. Gender distribution
      const { data: genderData } = await supabase.from('residents').select('gender').eq('is_active', true);
      const gCounts = (genderData || []).reduce((acc: any, curr) => {
        acc[curr.gender] = (acc[curr.gender] || 0) + 1;
        return acc;
      }, { MALE: 0, FEMALE: 0 });

      // 3. Property distribution
      const { data: propData } = await supabase.from('households').select('property_type').eq('is_active', true);
      const pCounts = (propData || []).reduce((acc: any, curr) => {
        acc[curr.property_type] = (acc[curr.property_type] || 0) + 1;
        return acc;
      }, { HOUSE: 0, APARTMENT: 0 });

      // 4. District Analysis (Real data from database)
      // Fetch households with district names to group them
      const { data: householdDistricts } = await supabase.from('households').select('districts(name)').eq('is_active', true);
      const districtGrouping = (householdDistricts || []).reduce((acc: any, curr: any) => {
        const name = curr.districts?.name || 'Noma\'lum';
        acc[name] = (acc[name] || 0) + 1;
        return acc;
      }, {});

      // Sort and take top 5
      const districtLabels = Object.keys(districtGrouping).sort((a, b) => districtGrouping[b] - districtGrouping[a]).slice(0, 5);
      const districtValues = districtLabels.map(label => districtGrouping[label]);

      const verifiedPercent = hCount ? Math.round((vCount! / hCount) * 100) : 0;

      setStats({
        households: hCount || 0,
        residents: rCount || 0,
        districts: dCount || 0,
        verified: verifiedPercent,
        gender: gCounts,
        property: pCounts,
        districtAnalysis: {
          labels: districtLabels.length > 0 ? districtLabels : ['Ma\'lumot yo\'q'],
          values: districtValues.length > 0 ? districtValues : [0]
        }
      });
    } catch (err) {
      console.error('Stat error:', err);
    } finally {
      setLoading(false);
    }
  }

  const chartOptions: any = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom',
        labels: { color: '#888', font: { size: 11, weight: '700' }, padding: 20 }
      },
      tooltip: {
        backgroundColor: '#1c1c1c',
        titleColor: '#fff',
        bodyColor: '#888',
        borderColor: '#3ecf8e',
        borderWidth: 1,
        padding: 12
      }
    },
    scales: {
      x: { grid: { display: false }, ticks: { color: '#666', font: { size: 10 } } },
      y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#666', font: { size: 10 } } }
    }
  };

  if (loading) {
    return (
      <div className="h-[60vh] flex flex-col items-center justify-center gap-4">
        <Loader2 className="animate-spin text-[#3ecf8e]" size={40} />
        <p className="text-gray-500 font-medium">Statistikalar tahlil qilinmoqda...</p>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Statistika</h1>
          <p className="text-gray-500 text-sm mt-1">Hudud va aholi bo'yicha real vaqtdagi tahlillar</p>
        </div>
        <button 
          onClick={fetchStats}
          className="flex items-center gap-2 px-4 py-2 bg-[#3ecf8e10] text-[#3ecf8e] border border-[#3ecf8e20] rounded-xl hover:bg-[#3ecf8e20] transition-all text-sm font-bold"
        >
          <RefreshCw size={16} />
          Yangilash
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { label: 'Jami Aholi', value: stats.residents, icon: Users, color: '#3ecf8e' },
          { label: 'Xonadonlar', value: stats.households, icon: Home, color: '#3b82f6' },
          { label: 'Tumanlar', value: stats.districts, icon: MapPin, color: '#f59e0b' },
          { label: 'Tasdiqlangan', value: stats.verified, icon: ShieldCheck, color: '#8b5cf6' },
        ].map((item, i) => (
          <div key={i} className="bg-[#171717] border border-white/5 p-6 rounded-2xl relative overflow-hidden group">
            <div className="w-12 h-12 rounded-xl flex items-center justify-center mb-4" style={{ backgroundColor: `${item.color}15`, color: item.color }}>
              <item.icon size={24} />
            </div>
            <div className="text-3xl font-bold text-white mb-1">
              {item.value.toLocaleString()}{item.label === 'Tasdiqlangan' ? '%' : ''}
            </div>
            <div className="text-xs text-gray-500 uppercase font-bold tracking-wider">{item.label}</div>
          </div>
        ))}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-[#171717] border border-white/5 p-8 rounded-3xl min-h-[400px] flex flex-col">
          <div className="flex items-center gap-3 mb-8">
            <TrendingUp className="text-[#3ecf8e]" size={20} />
            <h3 className="font-bold text-white uppercase text-xs tracking-widest text-gray-400">Hududlar tahlili (Top 5)</h3>
          </div>
          <div className="flex-1">
            <Bar 
              data={{
                labels: stats.districtAnalysis.labels,
                datasets: [{
                  label: 'Xonadonlar soni',
                  data: stats.districtAnalysis.values,
                  backgroundColor: 'rgba(62, 207, 142, 0.4)',
                  borderColor: '#3ecf8e',
                  borderWidth: 2,
                  borderRadius: 6
                }]
              }} 
              options={chartOptions} 
            />
          </div>
        </div>

        <div className="bg-[#171717] border border-white/5 p-8 rounded-3xl flex flex-col">
          <div className="flex items-center gap-3 mb-8">
            <Activity className="text-[#3ecf8e]" size={20} />
            <h3 className="font-bold text-white uppercase text-xs tracking-widest text-gray-400">Genderni taqsimlanishi</h3>
          </div>
          <div className="flex-1 min-h-[250px]">
            <Doughnut 
              data={{
                labels: ['Erkaklar', 'Ayollar'],
                datasets: [{
                  data: [stats.gender.MALE, stats.gender.FEMALE],
                  backgroundColor: ['#3ecf8e', '#3b82f6'],
                  borderWidth: 0,
                  hoverOffset: 10
                }]
              }} 
              options={chartOptions} 
            />
          </div>
        </div>

        <div className="bg-[#171717] border border-white/5 p-8 rounded-3xl flex flex-col">
          <div className="flex items-center gap-3 mb-8">
            <Home className="text-[#3ecf8e]" size={20} />
            <h3 className="font-bold text-white uppercase text-xs tracking-widest text-gray-400">Mulk turlari</h3>
          </div>
          <div className="flex-1 min-h-[250px]">
            <Pie 
              data={{
                labels: ['Hovli', 'Kvartira'],
                datasets: [{
                  data: [stats.property.HOUSE, stats.property.APARTMENT],
                  backgroundColor: ['#3ecf8e', '#8b5cf6'],
                  borderWidth: 0
                }]
              }} 
              options={chartOptions} 
            />
          </div>
        </div>

        <div className="lg:col-span-2 bg-gradient-to-br from-[#3ecf8e08] to-transparent border border-[#3ecf8e10] p-8 rounded-3xl flex items-center gap-6">
           <div className="w-16 h-16 bg-[#3ecf8e] text-black rounded-2xl flex items-center justify-center shadow-lg shadow-[#3ecf8e]/20 shrink-0">
              <ShieldCheck size={32} />
           </div>
           <div>
              <h3 className="text-xl font-bold text-white">Ma'lumotlar xavfsizligi</h3>
              <p className="text-gray-500 text-sm mt-1">Hozirgi vaqtda barcha ma'lumotlar Supabase 256-bit shifrlash tizimi orqali himoyalangan.</p>
           </div>
        </div>
      </div>
    </div>
  );
}
