import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export async function middleware(req: NextRequest) {
  const session = req.cookies.get('admin_session');
  const { pathname } = req.nextUrl;

  // Login sahifasida bo'lsa va sessiya bo'lsa, asosiy sahifaga yuboramiz
  if (pathname.startsWith('/login') && session) {
    return NextResponse.redirect(new URL('/', req.url));
  }

  // Sessiya yo'q bo'lsa va login sahifasida bo'lmasa, login'ga yuboramiz
  if (!session && !pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
