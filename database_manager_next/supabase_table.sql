-- Roles enum yaratish
CREATE TYPE user_role AS ENUM ('ADMIN', 'USER');

-- Profiles jadvalini yaratish (Auth users bilan bog'langan)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    role user_role DEFAULT 'USER',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) yoqish
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles'ni faqat egasi yoki ADMIN ko'ra oladi
CREATE POLICY "Profiles can be viewed by owner or admin" ON public.profiles
    FOR SELECT USING (auth.uid() = id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'ADMIN'
    ));

-- Foydalanuvchi ro'yxatdan o'tganda avtomatik profil yaratish uchun Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'USER'); -- Default 'USER', buni qo'lda ADMIN qilish kerak bo'ladi
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- DIQQAT: O'zingizni SUPERADMIN qilish uchun quyidagi SQL ni ishlating (UID ni o'zgartiring):
-- UPDATE public.profiles SET role = 'SUPERADMIN' WHERE email = 'SizningEmailingiz@gmail.com';
