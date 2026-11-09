-- Ícono (emoji) de cada categoría, elegido desde el panel admin.
-- Si queda vacío, el catálogo usa un ícono por defecto según el nombre.
alter table public.categorias add column if not exists icono text;

update public.categorias set icono = '🍜' where nombre = 'Ramens' and icono is null;
update public.categorias set icono = '🥤' where nombre = 'Bebidas' and icono is null;
update public.categorias set icono = '🍿' where nombre = 'Snacks' and icono is null;
