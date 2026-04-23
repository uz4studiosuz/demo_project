'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Users, BarChart3, Database, MapPin } from 'lucide-react';

const Sidebar = () => {
  const pathname = usePathname();

  const menuItems = [
    { name: 'Xonadonlar', href: '/', icon: LayoutDashboard },
    { name: 'Aholi', href: '/peoples', icon: Users },
    { name: 'Statistika', href: '/stat', icon: BarChart3 },
    { name: 'Hududlar', href: '/locations', icon: MapPin },
  ];

  return (
    <aside className="w-64 bg-[#1c1c1c] border-r border-white/5 text-[#888] h-screen flex flex-col p-6 fixed left-0 top-0">
      <div className="flex items-center gap-3 mb-10 text-white font-bold text-xl tracking-tight">
        <div className="w-9 h-9 bg-[#3ecf8e] text-black rounded-lg flex items-center justify-center">
          <Database size={20} />
        </div>
        <span>DB Manager</span>
      </div>

      <nav className="flex-1 space-y-1">
        {menuItems.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-all hover:bg-white/[0.03] hover:text-white ${
                isActive ? 'bg-[#3ecf8e10] text-[#3ecf8e] border-r-2 border-[#3ecf8e]' : ''
              }`}
            >
              <Icon size={18} />
              <span className="text-sm font-medium">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="text-xs text-gray-500 text-center">
        © 2024 Admin Panel
      </div>
    </aside>
  );
};

export default Sidebar;
