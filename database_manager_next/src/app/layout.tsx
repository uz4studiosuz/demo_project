'use client';

import { Inter } from "next/font/google";
import "./globals.css";
import Sidebar from "@/components/Sidebar";
import { usePathname, useRouter } from 'next/navigation';
import { useState, useEffect } from 'react';
import { LogOut, User as UserIcon, ChevronDown } from 'lucide-react';

const inter = Inter({ subsets: ["latin"] });

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="uz">
      <body className={`${inter.className} bg-[#1c1c1c] text-[#ededed] selection:bg-[#3ecf8e] selection:text-black`}>
        <LayoutContent>{children}</LayoutContent>
      </body>
    </html>
  );
}

function LayoutContent({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [adminName, setAdminName] = useState('Admin');
  const [showProfile, setShowProfile] = useState(false);
  const isLoginPage = pathname === '/login';

  useEffect(() => {
    const userJson = localStorage.getItem('admin_user');
    if (userJson) {
      const user = JSON.parse(userJson);
      setAdminName(user.first_name || 'Admin');
    }
  }, [pathname]);

  const handleSignOut = () => {
    document.cookie = "admin_session=; path=/; expires=Thu, 01 Jan 1970 00:00:00 UTC;";
    localStorage.removeItem('admin_user');
    router.push('/login');
  };

  if (isLoginPage) return <>{children}</>;

  return (
    <div className="flex">
      <Sidebar />
      <main className="flex-1 ml-64 p-8 min-h-screen">
        <header className="flex justify-between items-center mb-10 sticky top-0 bg-[#1c1c1c]/80 backdrop-blur-md z-40 py-2">


          <div className="relative">
            <button
              onClick={() => setShowProfile(!showProfile)}
              className="flex items-center gap-3 p-1.5 pr-3 hover:bg-white/5 rounded-full transition-all border border-transparent hover:border-white/5"
            >
              <div className="w-8 h-8 bg-[#3ecf8e] text-black rounded-full flex items-center justify-center font-bold text-xs shadow-lg shadow-[#3ecf8e]/20">
                {adminName[0].toUpperCase()}
              </div>
              <span className="text-sm font-medium text-gray-300">{adminName}</span>
              <ChevronDown size={14} className={`text-gray-500 transition-transform ${showProfile ? 'rotate-180' : ''}`} />
            </button>

            {showProfile && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowProfile(false)}></div>
                <div className="absolute right-0 mt-2 w-48 bg-[#171717] border border-white/5 rounded-xl shadow-2xl z-50 p-1.5 animate-in fade-in zoom-in-95 duration-200">
                  <div className="px-3 py-2 border-b border-white/5 mb-1">
                    <p className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Administrator</p>
                  </div>
                  <button className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-300 hover:bg-white/5 rounded-lg transition-colors">
                    <UserIcon size={16} />
                    Profil
                  </button>
                  <button
                    onClick={handleSignOut}
                    className="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                  >
                    <LogOut size={16} />
                    Chiqish
                  </button>
                </div>
              </>
            )}
          </div>
        </header>
        <div className="max-w-7xl mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
