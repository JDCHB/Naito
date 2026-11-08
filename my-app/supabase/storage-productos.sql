-- Espacio de fotos de productos en Supabase Storage.
-- Ya está aplicado en el proyecto actual; sirve como referencia si se
-- recrea el proyecto o se transfiere a otra cuenta.

-- Bucket público (las fotos se ven por su enlace), solo imágenes de hasta 2 MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('productos', 'productos', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Solo el admin (perfiles.rol = 'admin', ver public.es_admin()) puede gestionar fotos.
-- SELECT es necesario para que el admin pueda borrar sus archivos.
create policy "Fotos productos: admin ve" on storage.objects
    for select to authenticated
    using (bucket_id = 'productos' and public.es_admin());

create policy "Fotos productos: admin sube" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'productos' and public.es_admin());

create policy "Fotos productos: admin edita" on storage.objects
    for update to authenticated
    using (bucket_id = 'productos' and public.es_admin())
    with check (bucket_id = 'productos' and public.es_admin());

create policy "Fotos productos: admin borra" on storage.objects
    for delete to authenticated
    using (bucket_id = 'productos' and public.es_admin());
