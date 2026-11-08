<script>
    import { onMount } from "svelte";
    import { supabase } from "$lib/supabase";
    import { goto } from "$app/navigation";

    let user = $state(null);

    let productos = $state([]);
    let categorias = $state([]);

    let loading = $state(true);

    // ==========================================
    // AVISOS (TOAST)
    // ==========================================

    let mensaje = $state("");
    let tipoMensaje = $state("ok"); // "ok" | "error"
    let temporizadorMensaje;

    function notificar(texto, tipo = "ok") {
        mensaje = texto;
        tipoMensaje = tipo;

        clearTimeout(temporizadorMensaje);
        temporizadorMensaje = setTimeout(() => (mensaje = ""), 3500);
    }

    // ==========================================
    // BÚSQUEDA Y FILTROS
    // ==========================================

    let busqueda = $state("");
    let filtroCategoria = $state("todas");

    function normalizar(texto) {
        return (texto ?? "")
            .toLowerCase()
            .normalize("NFD")
            .replace(/[̀-ͯ]/g, "");
    }

    let productosFiltrados = $derived(
        productos.filter((producto) => {
            const coincideCategoria =
                filtroCategoria === "todas" ||
                producto.categoria_id === filtroCategoria;

            const coincideBusqueda = normalizar(producto.nombre).includes(
                normalizar(busqueda.trim()),
            );

            return coincideCategoria && coincideBusqueda;
        }),
    );

    let totalActivos = $derived(productos.filter((p) => p.activo).length);

    // ==========================================
    // FORMULARIO
    // ==========================================

    let formularioAbierto = $state(false);
    let editando = $state(false);
    let guardando = $state(false);

    let productoId = $state(null);
    let nombre = $state("");
    let descripcion = $state("");
    let precio = $state("");
    let categoriaId = $state("");
    let imagenUrl = $state("");
    let activo = $state(true);
    let nivelPicante = $state(null);
    let imagenRota = $state(false);

    // ==========================================
    // SUBIR FOTOS A SUPABASE STORAGE
    // ==========================================

    const BUCKET = "productos";
    const MAX_LADO = 900; // px del lado más largo después de comprimir

    let subiendoFoto = $state(false);
    let imagenOriginal = ""; // foto que tenía el producto al abrir el formulario
    let fotoNueva = null; // ruta subida en esta edición y aún no guardada

    // Devuelve la ruta dentro del bucket si la URL es de nuestro Storage
    function rutaEnBucket(url) {
        const marca = `/storage/v1/object/public/${BUCKET}/`;
        const i = (url ?? "").indexOf(marca);
        return i === -1 ? null : decodeURIComponent(url.slice(i + marca.length));
    }

    async function borrarFoto(url) {
        const ruta = rutaEnBucket(url);
        if (!ruta) return;

        const { data, error } = await supabase.storage.from(BUCKET).remove([ruta]);
        // Supabase no da error si no tenía permiso: devuelve la lista vacía
        if (error || !data?.length) {
            console.error("No se pudo borrar la foto:", ruta, error);
        }
    }

    function nombreArchivo(texto) {
        const base = normalizar(texto)
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-|-$/g, "")
            .slice(0, 40);
        return `${Date.now()}-${base || "producto"}`;
    }

    // Achica y comprime la foto en el navegador antes de subirla
    async function comprimirImagen(archivo) {
        const bitmap = await createImageBitmap(archivo);
        const escala = Math.min(1, MAX_LADO / Math.max(bitmap.width, bitmap.height));
        const ancho = Math.round(bitmap.width * escala);
        const alto = Math.round(bitmap.height * escala);

        const canvas = document.createElement("canvas");
        canvas.width = ancho;
        canvas.height = alto;
        canvas.getContext("2d").drawImage(bitmap, 0, 0, ancho, alto);
        bitmap.close?.();

        const aBlob = (tipo, calidad) =>
            new Promise((resolve) => canvas.toBlob(resolve, tipo, calidad));

        let blob = await aBlob("image/webp", 0.8);
        // Safari antiguo no genera WebP: usamos JPG
        if (!blob || blob.type !== "image/webp") {
            blob = await aBlob("image/jpeg", 0.82);
        }
        return blob;
    }

    async function subirFoto(event) {
        const input = event.currentTarget;
        const archivo = input.files?.[0];
        input.value = ""; // permite volver a elegir el mismo archivo

        if (!archivo) return;

        if (!archivo.type.startsWith("image/")) {
            notificar("El archivo debe ser una imagen.", "error");
            return;
        }

        subiendoFoto = true;

        try {
            const blob = await comprimirImagen(archivo);
            const extension = blob.type === "image/webp" ? "webp" : "jpg";
            const ruta = `${nombreArchivo(nombre)}.${extension}`;

            const { error } = await supabase.storage
                .from(BUCKET)
                .upload(ruta, blob, {
                    contentType: blob.type,
                    cacheControl: "31536000",
                    upsert: false,
                });

            if (error) throw error;

            // Si ya había subido otra foto en esta misma edición, se borra
            if (fotoNueva) await borrarFoto(fotoNueva);

            const { data } = supabase.storage.from(BUCKET).getPublicUrl(ruta);

            imagenUrl = data.publicUrl;
            fotoNueva = data.publicUrl;
            imagenRota = false;

            notificar(`Foto subida (${Math.round(blob.size / 1024)} KB).`);
        } catch (error) {
            console.error("Error subiendo foto:", error);
            notificar("No se pudo subir la foto. Intenta de nuevo.", "error");
        } finally {
            subiendoFoto = false;
        }
    }

    const nivelesPicante = [
        { valor: null, texto: "No aplica" },
        { valor: 1, texto: "Leve" },
        { valor: 2, texto: "Medio" },
        { valor: 3, texto: "Fuerte" },
        { valor: 4, texto: "Muy picante" },
        { valor: 5, texto: "Súper picante" },
    ];

    // ==========================================
    // CARGAR DATOS
    // ==========================================

    onMount(async () => {
        const { data: userData, error: userError } =
            await supabase.auth.getUser();

        if (userError || !userData.user) {
            goto("/admin/login");
            return;
        }

        user = userData.user;

        await cargarDatos();

        loading = false;
    });

    async function cargarDatos() {
        // Categorías
        const { data: categoriasData, error: categoriasError } = await supabase
            .from("categorias")
            .select("*")
            .order("id");

        if (categoriasError) {
            console.error("Error obteniendo categorías:", categoriasError);

            notificar("Error cargando categorías.", "error");
            return;
        }

        categorias = categoriasData;

        // Productos
        const { data: productosData, error: productosError } = await supabase
            .from("productos")
            .select("*")
            .order("id");

        if (productosError) {
            console.error("Error obteniendo productos:", productosError);

            notificar("Error cargando productos.", "error");
            return;
        }

        productos = productosData;
    }

    // ==========================================
    // OBTENER CATEGORÍA
    // ==========================================

    function obtenerCategoria(categoriaId) {
        const categoria = categorias.find(
            (categoria) => categoria.id === categoriaId,
        );

        return categoria?.nombre ?? "Sin categoría";
    }

    function formatPrice(valor) {
        return `$${Number(valor).toLocaleString("es-CO")}`;
    }

    // ==========================================
    // ABRIR FORMULARIO NUEVO
    // ==========================================

    function nuevoProducto() {
        editando = false;

        productoId = null;
        nombre = "";
        descripcion = "";
        precio = "";
        categoriaId =
            filtroCategoria !== "todas"
                ? filtroCategoria
                : categorias.length > 0
                  ? categorias[0].id
                  : "";
        imagenUrl = "";
        activo = true;
        nivelPicante = null;
        imagenRota = false;
        imagenOriginal = imagenUrl;
        fotoNueva = null;

        formularioAbierto = true;
    }

    // ==========================================
    // ABRIR FORMULARIO EDITAR
    // ==========================================

    function editarProducto(producto) {
        editando = true;

        productoId = producto.id;
        nombre = producto.nombre ?? "";
        descripcion = producto.descripcion ?? "";
        precio = producto.precio;
        categoriaId = producto.categoria_id;
        imagenUrl = producto.imagen_url ?? "";
        activo = producto.activo;
        nivelPicante = producto.nivel_picante ?? null;
        imagenRota = false;
        imagenOriginal = imagenUrl;
        fotoNueva = null;

        formularioAbierto = true;
    }

    // ==========================================
    // CERRAR FORMULARIO
    // ==========================================

    function cerrarFormulario() {
        if (guardando || subiendoFoto) return;

        // Si subió una foto pero no guardó, se borra para no ocupar espacio
        if (fotoNueva) {
            borrarFoto(fotoNueva);
            fotoNueva = null;
        }

        formularioAbierto = false;
    }

    // ==========================================
    // GUARDAR PRODUCTO
    // ==========================================

    async function guardarProducto() {
        if (!nombre.trim() || !descripcion.trim() || !precio || !categoriaId) {
            notificar("Completa todos los campos obligatorios.", "error");
            return;
        }

        const producto = {
            nombre: nombre.trim(),
            descripcion: descripcion.trim(),
            precio: Number(precio),
            categoria_id: Number(categoriaId),
            imagen_url: imagenUrl.trim(),
            activo: activo,
            nivel_picante: nivelPicante,
        };

        guardando = true;

        // ======================================
        // EDITAR
        // ======================================

        if (editando) {
            const { data, error } = await supabase
                .from("productos")
                .update(producto)
                .eq("id", productoId)
                .select()
                .single();

            guardando = false;

            if (error) {
                console.error("Error actualizando producto:", error);

                notificar("No se pudo actualizar el producto.", "error");
                return;
            }

            productos = productos.map((p) => (p.id === productoId ? data : p));

            notificar("Producto actualizado correctamente.");
        }

        // ======================================
        // CREAR
        // ======================================
        else {
            const { data, error } = await supabase
                .from("productos")
                .insert(producto)
                .select()
                .single();

            guardando = false;

            if (error) {
                console.error("Error creando producto:", error);

                notificar("No se pudo crear el producto.", "error");
                return;
            }

            productos = [...productos, data];

            notificar("Producto creado correctamente.");
        }

        // Si cambió la foto, se borra la anterior del Storage
        if (imagenOriginal && imagenOriginal !== producto.imagen_url) {
            borrarFoto(imagenOriginal);
        }

        fotoNueva = null;
        formularioAbierto = false;
    }

    // ==========================================
    // ACTIVAR / DESACTIVAR
    // ==========================================

    async function cambiarEstado(producto) {
        const nuevoEstado = !producto.activo;

        const { error } = await supabase
            .from("productos")
            .update({
                activo: nuevoEstado,
            })
            .eq("id", producto.id);

        if (error) {
            console.error("Error cambiando estado:", error);

            notificar("No se pudo cambiar el estado.", "error");
            return;
        }

        productos = productos.map((p) =>
            p.id === producto.id
                ? {
                      ...p,
                      activo: nuevoEstado,
                  }
                : p,
        );

        notificar(
            nuevoEstado
                ? `"${producto.nombre}" ahora se ve en el catálogo.`
                : `"${producto.nombre}" quedó oculto del catálogo.`,
        );
    }

    // ==========================================
    // ELIMINAR
    // ==========================================

    async function eliminarProducto(producto) {
        const confirmar = confirm(
            `¿Seguro que quieres eliminar "${producto.nombre}"? Esta acción no se puede deshacer.`,
        );

        if (!confirmar) return;

        const { error } = await supabase
            .from("productos")
            .delete()
            .eq("id", producto.id);

        if (error) {
            console.error("Error eliminando producto:", error);

            notificar("No se pudo eliminar el producto.", "error");
            return;
        }

        productos = productos.filter((p) => p.id !== producto.id);

        borrarFoto(producto.imagen_url);

        notificar("Producto eliminado correctamente.");
    }

    // ==========================================
    // CERRAR SESIÓN
    // ==========================================

    async function cerrarSesion() {
        await supabase.auth.signOut();

        goto("/admin/login");
    }
</script>

<svelte:head>
    <title>Panel · Naito House</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
    <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Dela+Gothic+One&family=Zen+Kaku+Gothic+New:wght@400;500;700;900&display=swap"
    />
</svelte:head>

<svelte:window
    onkeydown={(event) => {
        if (event.key === "Escape" && formularioAbierto) cerrarFormulario();
    }}
/>

{#if loading}
    <div class="loading-screen">
        <div class="loader">
            <!-- MARIPOSA -->
            <div class="loader">
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="193"
                    height="369"
                    x="0"
                    y="0"
                    version="1.1"
                    viewBox="0 0 18.528 35.424"
                >
                    <path
                        fill="#000"
                        d="M3.358 35.05c.435-.175.646-.408.861-.95.374-.94.698-1.52 1.145-2.05.78-.92 1.757-1.638 2.666-1.957.603-.212.9-.204 1.505.041.843.343 1.597.25 2.062-.254.95-1.029 3.95-6.873 5.841-11.376.869-2.07.831-1.882.797-3.962-.034-2.106-.024-2.064-.927-3.887-1.639-3.31-4.426-6.582-7.147-8.392C8.71 1.298 6.715.504 5.296.328c-.718-.09-2.465-.001-3.183.16C.943.752.279 1.268.279 1.917c0 .119.437 1.136.97 2.26.533 1.126 1.044 2.291 1.135 2.591.334 1.106.776 3.567.945 5.27.065.652.357 1.286.751 1.633.419.367 1.351.786 1.964.883.286.044.534.096.553.115.018.018-.129.128-.327.244-.761.446-1.432 1.439-1.74 2.574-.216.802-.194 2.914.045 4.121.24 1.212.575 2.318 1.031 3.403.46 1.092.535 1.458.439 2.135-.223 1.575-1.958 4.03-3.489 4.937-.693.41-.885.587-1.066.98-.173.375-.185.535-.069.953.223.802 1.206 1.326 1.937 1.033z"
                    ></path>
                </svg>

                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="25"
                    height="150"
                    x="0"
                    y="0"
                    version="1.1"
                    viewBox="0 0 2.4 14.4"
                >
                    <path
                        fill="#000"
                        d="M2.2 13c0 .641-.447 1.16-1 1.16-.553 0-1-.519-1-1.16V1.4C.2.759.647.24 1.2.24c.553 0 1 .519 1 1.16z"
                    ></path>
                </svg>

                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="193"
                    height="369"
                    x="0"
                    y="0"
                    version="1.1"
                    viewBox="0 0 18.528 35.424"
                >
                    <path
                        fill="#000"
                        d="M15.105 35.155c-.42-.196-.627-.482-.902-1.253-.544-1.517-2.145-3.126-3.636-3.652-.69-.243-.887-.242-1.486.01-.617.26-1.342.278-1.798.045-.555-.283-1.76-2.262-3.476-5.708C2.628 22.232.984 18.575.455 17.144c-.236-.637-.237-.655-.237-2.485 0-2.164.01-2.209.9-4.013 1.011-2.049 2.53-4.189 4.185-5.9C7.679 2.293 9.783.995 12.49.313c.782-.197 1.554-.236 2.695-.137 1.619.14 2.38.38 2.882.909.21.22.246.321.243.684-.002.373-.122.67-.959 2.395-1.277 2.63-1.59 3.806-2.035 7.63-.111.951-.316 1.426-.809 1.87-.52.47-1.306.807-2.165.928l-.391.054.35.224c.897.574 1.58 1.674 1.834 2.956.193.969.12 2.791-.164 4.15-.222 1.061-.696 2.518-1.12 3.443-.336.735-.411 1.584-.203 2.3.505 1.738 2.056 3.692 3.736 4.705.693.417.938.83.874 1.476-.104 1.071-1.193 1.706-2.153 1.256z"
                    ></path>
                </svg>
            </div>
        </div>

        <p>Cargando panel...</p>
    </div>
{:else if user}
    <main>
        <!-- ENCABEZADO -->

        <header>
            <div class="brand">
                <img src="/Logo.jpeg" alt="Naito House" />

                <div>
                    <p class="eyebrow">Naito House</p>
                    <h1>Panel administrativo</h1>
                </div>
            </div>

            <div class="header-actions">
                <span class="session" title={user.email}>
                    <span class="dot"></span>
                    {user.email}
                </span>

                <a class="btn-ghost" href="/" target="_blank" rel="noopener">
                    Ver catálogo ↗
                </a>

                <button class="btn-ghost" onclick={cerrarSesion}>
                    Cerrar sesión
                </button>
            </div>
        </header>

        <!-- RESUMEN -->

        <div class="stats">
            <div class="stat">
                <span class="stat-value">{productos.length}</span>
                <span class="stat-label">Productos</span>
            </div>

            <div class="stat">
                <span class="stat-value ok">{totalActivos}</span>
                <span class="stat-label">Visibles en el catálogo</span>
            </div>

            <div class="stat">
                <span class="stat-value muted">
                    {productos.length - totalActivos}
                </span>
                <span class="stat-label">Ocultos</span>
            </div>

            <div class="stat">
                <span class="stat-value">{categorias.length}</span>
                <span class="stat-label">Categorías</span>
            </div>
        </div>

        <!-- PRODUCTOS -->

        <section>
            <div class="section-header">
                <h2>Productos</h2>

                <button class="btn-primary" onclick={nuevoProducto}>
                    + Nuevo producto
                </button>
            </div>

            <div class="toolbar">
                <label class="search">
                    <span aria-hidden="true">⌕</span>

                    <input
                        type="search"
                        placeholder="Buscar producto..."
                        aria-label="Buscar producto"
                        bind:value={busqueda}
                    />
                </label>

                <div class="chips" role="group" aria-label="Filtrar por categoría">
                    <button
                        class="chip"
                        class:selected={filtroCategoria === "todas"}
                        onclick={() => (filtroCategoria = "todas")}
                    >
                        Todas
                    </button>

                    {#each categorias as categoria (categoria.id)}
                        <button
                            class="chip"
                            class:selected={filtroCategoria === categoria.id}
                            onclick={() => (filtroCategoria = categoria.id)}
                        >
                            {categoria.nombre}
                        </button>
                    {/each}
                </div>
            </div>

            <!-- LISTA -->

            <div class="lista">
                <div class="fila fila-head" aria-hidden="true">
                    <span></span>
                    <span>Producto</span>
                    <span>Categoría</span>
                    <span>Precio</span>
                    <span>Picante</span>
                    <span>Visible</span>
                    <span></span>
                </div>

                {#each productosFiltrados as producto (producto.id)}
                    <div class="fila" class:oculto={!producto.activo}>
                        <div class="thumb">
                            {#if /^(\/|https?:\/\/)/.test(producto.imagen_url ?? "")}
                                <img
                                    src={producto.imagen_url}
                                    alt=""
                                    loading="lazy"
                                />
                            {:else}
                                <span>🍜</span>
                            {/if}
                        </div>

                        <div class="info">
                            <strong>{producto.nombre}</strong>
                            <small>{producto.descripcion}</small>
                        </div>

                        <div>
                            <span class="pill">
                                {obtenerCategoria(producto.categoria_id)}
                            </span>
                        </div>

                        <div class="precio">{formatPrice(producto.precio)}</div>

                        <div class="picante">
                            {#if producto.nivel_picante}
                                {#each [1, 2, 3, 4, 5] as n}
                                    <span
                                        class="chili"
                                        class:on={n <= producto.nivel_picante}
                                        >🌶️</span
                                    >
                                {/each}
                            {:else}
                                <span class="na">—</span>
                            {/if}
                        </div>

                        <div class="estado">
                            <button
                                class="switch"
                                role="switch"
                                aria-checked={producto.activo}
                                aria-label="Mostrar {producto.nombre} en el catálogo"
                                onclick={() => cambiarEstado(producto)}
                            >
                                <span class="knob"></span>
                            </button>

                            <span class="estado-texto">
                                {producto.activo ? "Visible" : "Oculto"}
                            </span>
                        </div>

                        <div class="acciones">
                            <button onclick={() => editarProducto(producto)}>
                                ✎ Editar
                            </button>

                            <button
                                class="btn-danger"
                                aria-label="Eliminar {producto.nombre}"
                                title="Eliminar"
                                onclick={() => eliminarProducto(producto)}
                            >
                                🗑
                            </button>
                        </div>
                    </div>
                {:else}
                    <div class="vacio">
                        <span>🔍</span>
                        <p>
                            {productos.length === 0
                                ? "Todavía no hay productos. Crea el primero."
                                : "No hay productos que coincidan con la búsqueda."}
                        </p>
                    </div>
                {/each}
            </div>
        </section>

        <!-- FORMULARIO -->

        {#if formularioAbierto}
            <div class="modal">
                <button
                    class="modal-backdrop"
                    aria-label="Cerrar formulario"
                    onclick={cerrarFormulario}
                ></button>

                <form
                    class="modal-content"
                    onsubmit={(event) => {
                        event.preventDefault();
                        guardarProducto();
                    }}
                >
                    <div class="modal-header">
                        <h2>
                            {editando ? "Editar producto" : "Nuevo producto"}
                        </h2>

                        <button
                            type="button"
                            class="close"
                            aria-label="Cerrar"
                            onclick={cerrarFormulario}
                        >
                            ×
                        </button>
                    </div>

                    <div class="modal-body">
                        <label>
                            Nombre *

                            <input
                                type="text"
                                bind:value={nombre}
                                placeholder="Ej: Buldak Carbonara"
                                required
                            />
                        </label>

                        <label>
                            Descripción *

                            <textarea
                                bind:value={descripcion}
                                placeholder="Cuéntale al cliente qué trae y a qué sabe."
                                required
                            ></textarea>
                        </label>

                        <div class="dos-columnas">
                            <label>
                                Precio *

                                <span class="input-precio">
                                    <span>$</span>
                                    <input
                                        type="number"
                                        min="0"
                                        step="100"
                                        bind:value={precio}
                                        placeholder="19000"
                                        required
                                    />
                                </span>
                            </label>

                            <label>
                                Categoría *

                                <select bind:value={categoriaId}>
                                    {#each categorias as categoria (categoria.id)}
                                        <option value={categoria.id}>
                                            {categoria.nombre}
                                        </option>
                                    {/each}
                                </select>
                            </label>
                        </div>

                        <fieldset>
                            <legend>Nivel de picante</legend>

                            <div class="niveles">
                                {#each nivelesPicante as nivel}
                                    <button
                                        type="button"
                                        class="nivel"
                                        class:selected={nivelPicante ===
                                            nivel.valor}
                                        onclick={() =>
                                            (nivelPicante = nivel.valor)}
                                    >
                                        <span class="nivel-chiles">
                                            {nivel.valor
                                                ? "🌶️".repeat(nivel.valor)
                                                : "🚫"}
                                        </span>
                                        <span>{nivel.texto}</span>
                                    </button>
                                {/each}
                            </div>
                        </fieldset>

                        <div class="imagen-campo">
                            <div class="preview" class:cargando={subiendoFoto}>
                                {#if subiendoFoto}
                                    <span class="spinner" aria-hidden="true"></span>
                                {:else if imagenUrl.trim() && !imagenRota}
                                    <img
                                        src={imagenUrl}
                                        alt="Vista previa"
                                        onerror={() => (imagenRota = true)}
                                    />
                                {:else}
                                    <span>
                                        {imagenRota ? "⚠️" : "🖼️"}
                                    </span>
                                {/if}
                            </div>

                            <div class="foto-acciones">
                                <span class="campo-titulo">Foto del producto</span>

                                <label
                                    class="btn-subir"
                                    class:disabled={subiendoFoto}
                                >
                                    <input
                                        type="file"
                                        accept="image/jpeg,image/png,image/webp"
                                        onchange={subirFoto}
                                        disabled={subiendoFoto}
                                    />
                                    {#if subiendoFoto}
                                        Subiendo foto...
                                    {:else}
                                        📷 {imagenUrl.trim()
                                            ? "Cambiar foto"
                                            : "Subir foto"}
                                    {/if}
                                </label>

                                {#if imagenRota}
                                    <small class="ayuda error">
                                        No se pudo cargar la foto. Prueba
                                        subiéndola de nuevo.
                                    </small>
                                {:else}
                                    <small class="ayuda">
                                        Desde el celular o el computador. Se
                                        achica automáticamente.
                                    </small>
                                {/if}

                                <details class="ruta-manual">
                                    <summary>Usar una ruta o enlace</summary>

                                    <input
                                        type="text"
                                        aria-label="Ruta o enlace de la imagen"
                                        bind:value={imagenUrl}
                                        oninput={() => (imagenRota = false)}
                                        placeholder="/Productos/imagen.jpg"
                                    />
                                </details>
                            </div>
                        </div>

                        <label class="toggle">
                            <input type="checkbox" bind:checked={activo} />

                            <span class="switch-visual" aria-hidden="true">
                                <span class="knob"></span>
                            </span>

                            <span>
                                <strong>Visible en el catálogo</strong>
                                <small>
                                    Si lo apagas, el producto queda guardado
                                    pero los clientes no lo ven.
                                </small>
                            </span>
                        </label>
                    </div>

                    <div class="modal-actions">
                        <button
                            type="button"
                            class="btn-ghost"
                            onclick={cerrarFormulario}
                            disabled={guardando}
                        >
                            Cancelar
                        </button>

                        <button
                            type="submit"
                            class="btn-primary"
                            disabled={guardando}
                        >
                            {#if guardando}
                                Guardando...
                            {:else}
                                {editando ? "Guardar cambios" : "Crear producto"}
                            {/if}
                        </button>
                    </div>
                </form>
            </div>
        {/if}

        <!-- AVISO -->

        {#if mensaje}
            <div class="toast" class:error={tipoMensaje === "error"} role="status">
                <span>{tipoMensaje === "error" ? "⚠️" : "✓"}</span>
                {mensaje}
            </div>
        {/if}
    </main>
{/if}

<style>
    /* ==========================================
   PANTALLA DE CARGA
========================================== */

    .loading-screen {
        min-height: 100vh;

        display: flex;
        flex-direction: column;

        align-items: center;
        justify-content: center;

        background: radial-gradient(
                circle at center,
                rgba(157, 21, 21, 0.12),
                transparent 35%
            ),
            #0d0d0d;

        color: #d4af37;
    }

    .loading-screen p {
        margin-top: 25px;

        color: #aaa;

        font-size: 14px;

        letter-spacing: 1px;
    }

    /* ==========================================
   LOADER MARIPOSA
========================================== */

    .loader {
        --sizeLoader: 60px;
        --sizeLoaderHalf: calc(var(--sizeLoader) / 2);
        --stepBtf: calc(var(--sizeLoader) / 10);

        display: flex;

        position: relative;

        flex-direction: row;

        justify-content: center;
        align-items: center;

        width: var(--sizeLoader);
        height: var(--sizeLoader);

        background: radial-gradient(#d4af37aa, transparent 30%);
    }

    .loader:hover {
        cursor: progress;
    }

    .loader:not([anim1]) {
        right: var(--sizeLoaderHalf);

        transform-origin: center right;

        animation: moveAround 2s linear infinite;
    }

    .loader svg:nth-child(1) {
        position: relative;

        height: 100%;

        left: 2%;

        transform-origin: center right;

        animation: wing 0.2s ease-in-out infinite;

        /* Dorado Mikaito */
        filter: brightness(0) saturate(100%) invert(73%) sepia(55%)
            saturate(700%) hue-rotate(5deg) brightness(92%);
    }

    .loader svg:nth-child(2) {
        height: 50%;

        filter: brightness(0) saturate(100%) invert(73%) sepia(55%)
            saturate(700%) hue-rotate(5deg) brightness(92%);
    }

    .loader svg:nth-child(3) {
        position: relative;

        height: 100%;

        left: -2%;

        transform-origin: center left;

        animation: wing 0.25s ease-in-out infinite;

        filter: brightness(0) saturate(100%) invert(73%) sepia(55%)
            saturate(700%) hue-rotate(5deg) brightness(92%);
    }

    @keyframes wing {
        0% {
            transform: rotateY(0deg);
        }

        50% {
            transform: rotateY(60deg);
        }

        100% {
            transform: rotateY(0deg);
        }
    }

    @keyframes moveAround {
        0% {
            transform: rotate(0deg);
        }

        100% {
            transform: rotate(360deg);
        }
    }
    /* ==========================================
   COLORES DEL PANEL
========================================== */

    main {
        --gold: #d4af37;
        --gold-soft: rgba(212, 175, 55, 0.25);
        --red: #b51c1c;
        --red-dark: #9d1515;
        --red-bright: #c92323;
        --bg: #0d0d0d;
        --surface: #151515;
        --surface-2: #1c1c1c;
        --border: #292929;
        --text: #f5f1e8;
        --muted: #9a9a9a;
        --ok: #68c46a;
    }

    /* ==========================================
   ESTILO GENERAL
========================================== */

    :global(body) {
        margin: 0;

        background:
            radial-gradient(
                circle at top right,
                rgba(139, 0, 0, 0.14),
                transparent 35%
            ),
            radial-gradient(
                circle at bottom left,
                rgba(212, 175, 55, 0.06),
                transparent 30%
            ),
            #0d0d0d;
        background-attachment: fixed;

        color: #f5f1e8;

        font-family: "Zen Kaku Gothic New", Arial, Helvetica, sans-serif;

        -webkit-font-smoothing: antialiased;
    }

    main {
        min-height: 100vh;

        padding: 36px 40px 80px;

        max-width: 1300px;
        margin: auto;

        box-sizing: border-box;
    }

    main :global(*) {
        box-sizing: border-box;
    }

    /* ==========================================
   HEADER
========================================== */

    header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 20px;
        flex-wrap: wrap;

        padding-bottom: 24px;
        margin-bottom: 28px;

        border-bottom: 1px solid var(--gold-soft);
    }

    .brand {
        display: flex;
        align-items: center;
        gap: 16px;
    }

    .brand img {
        width: 58px;
        height: 58px;

        border-radius: 50%;
        border: 2px solid var(--gold);

        object-fit: cover;

        box-shadow: 0 0 0 4px rgba(212, 175, 55, 0.1);
    }

    .eyebrow {
        margin: 0 0 4px;

        color: var(--muted);

        font-size: 11px;
        font-weight: 700;
        letter-spacing: 2.5px;
        text-transform: uppercase;
    }

    header h1 {
        margin: 0;

        color: var(--gold);

        font-family: "Dela Gothic One", sans-serif;
        font-weight: 400;
        font-size: 28px;
        line-height: 1.15;
    }

    .header-actions {
        display: flex;
        align-items: center;
        gap: 10px;
        flex-wrap: wrap;
    }

    .session {
        display: inline-flex;
        align-items: center;
        gap: 8px;

        max-width: 260px;

        padding: 8px 12px;

        border: 1px solid var(--border);
        border-radius: 999px;

        color: var(--muted);

        font-size: 13px;

        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
    }

    .dot {
        width: 8px;
        height: 8px;

        flex-shrink: 0;

        border-radius: 50%;

        background: var(--ok);

        box-shadow: 0 0 0 3px rgba(104, 196, 106, 0.2);
    }

    /* ==========================================
   BOTONES
========================================== */

    button,
    .btn-ghost {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 6px;

        padding: 9px 16px;

        border: 1px solid transparent;
        border-radius: 9px;

        background: #242424;
        color: #eee;

        font-family: inherit;
        font-size: 14px;
        font-weight: 700;

        text-decoration: none;

        cursor: pointer;

        transition:
            background 0.2s ease,
            color 0.2s ease,
            border-color 0.2s ease,
            transform 0.2s ease,
            box-shadow 0.2s ease;
    }

    button:hover,
    .btn-ghost:hover {
        background: #303030;
        border-color: #4a4a4a;
    }

    button:active {
        transform: scale(0.97);
    }

    button:disabled {
        opacity: 0.55;
        cursor: not-allowed;
    }

    button:focus-visible,
    .btn-ghost:focus-visible,
    input:focus-visible,
    select:focus-visible,
    textarea:focus-visible {
        outline: 2px solid var(--gold);
        outline-offset: 2px;
    }

    .btn-ghost {
        background: transparent;
        border-color: var(--border);
    }

    .btn-primary {
        background: linear-gradient(135deg, var(--red-dark), var(--red));
        border: 1px solid var(--red);
        color: #fff;

        box-shadow: 0 4px 15px rgba(150, 0, 0, 0.25);
    }

    .btn-primary:hover {
        background: linear-gradient(135deg, var(--red), var(--red-bright));
        border-color: var(--gold);

        box-shadow: 0 6px 20px rgba(150, 0, 0, 0.4);
    }

    .btn-danger {
        color: #e35d5d;
        background: rgba(180, 20, 20, 0.08);
        border: 1px solid rgba(180, 20, 20, 0.25);
    }

    .btn-danger:hover {
        color: white;
        background: var(--red-dark);
        border-color: var(--red-bright);
    }

    /* ==========================================
   RESUMEN
========================================== */

    .stats {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 14px;

        margin-bottom: 24px;
    }

    .stat {
        display: flex;
        flex-direction: column;
        gap: 4px;

        padding: 16px 18px;

        background: var(--surface);

        border: 1px solid var(--border);
        border-radius: 14px;
    }

    .stat-value {
        color: var(--text);

        font-size: 28px;
        font-weight: 900;
        font-variant-numeric: tabular-nums;
        line-height: 1;
    }

    .stat-value.ok {
        color: var(--ok);
    }

    .stat-value.muted {
        color: var(--muted);
    }

    .stat-label {
        color: var(--muted);

        font-size: 12px;
        font-weight: 500;
    }

    /* ==========================================
   SECCIÓN PRODUCTOS
========================================== */

    section {
        background: var(--surface);

        border: 1px solid var(--border);
        border-radius: 16px;

        padding: 24px;

        box-shadow: 0 10px 35px rgba(0, 0, 0, 0.35);
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 15px;

        margin-bottom: 18px;
    }

    .section-header h2 {
        margin: 0;

        color: var(--text);

        font-size: 22px;
        font-weight: 900;
    }

    /* ==========================================
   BÚSQUEDA Y FILTROS
========================================== */

    .toolbar {
        display: flex;
        align-items: center;
        gap: 14px;
        flex-wrap: wrap;

        margin-bottom: 18px;
    }

    .search {
        position: relative;

        flex: 1 1 260px;
        max-width: 360px;
    }

    .search span {
        position: absolute;
        left: 13px;
        top: 50%;

        transform: translateY(-50%);

        color: var(--muted);

        font-size: 17px;

        pointer-events: none;
    }

    .search input {
        padding-left: 36px;
    }

    .chips {
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
    }

    .chip {
        padding: 7px 14px;

        border: 1px solid var(--border);
        border-radius: 999px;

        background: transparent;
        color: var(--muted);

        font-size: 13px;
    }

    .chip.selected {
        background: rgba(212, 175, 55, 0.12);
        border-color: var(--gold);
        color: var(--gold);
    }

    /* ==========================================
   LISTA DE PRODUCTOS
========================================== */

    .lista {
        border: 1px solid var(--border);
        border-radius: 12px;

        overflow: hidden;

        background: #111;
    }

    .fila {
        display: grid;
        grid-template-columns: 56px minmax(0, 1fr) 120px 100px 110px 120px 150px;
        align-items: center;
        gap: 16px;

        padding: 12px 16px;

        border-bottom: 1px solid var(--border);

        transition:
            background 0.2s ease,
            opacity 0.2s ease;
    }

    .fila:last-child {
        border-bottom: none;
    }

    .fila:not(.fila-head):hover {
        background: rgba(212, 175, 55, 0.045);
    }

    .fila-head {
        padding-top: 11px;
        padding-bottom: 11px;

        background: var(--surface-2);

        color: var(--gold);

        font-size: 11px;
        font-weight: 700;
        letter-spacing: 1px;
        text-transform: uppercase;
    }

    .fila.oculto .thumb,
    .fila.oculto .info,
    .fila.oculto .precio,
    .fila.oculto .picante {
        opacity: 0.45;
    }

    .thumb {
        width: 56px;
        height: 56px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 10px;

        background: #1f1f1f;

        overflow: hidden;
    }

    .thumb img {
        width: 100%;
        height: 100%;

        object-fit: cover;
    }

    .thumb span {
        font-size: 24px;
    }

    .info {
        display: flex;
        flex-direction: column;
        gap: 3px;

        min-width: 0;
    }

    .info strong {
        color: #fff;

        font-size: 15px;
    }

    .info small {
        color: var(--muted);

        font-size: 12px;

        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
    }

    .pill {
        display: inline-block;

        padding: 4px 10px;

        border-radius: 999px;

        background: #232323;
        color: #d7d7d7;

        font-size: 12px;
        font-weight: 500;
    }

    .precio {
        color: #fff;

        font-weight: 700;
        font-variant-numeric: tabular-nums;
    }

    .picante {
        display: flex;
        gap: 1px;
    }

    .chili {
        font-size: 12px;

        filter: grayscale(1);
        opacity: 0.25;
    }

    .chili.on {
        filter: none;
        opacity: 1;
    }

    .na {
        color: #555;
    }

    /* ==========================================
   INTERRUPTOR VISIBLE / OCULTO
========================================== */

    .estado {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .switch,
    .switch-visual {
        position: relative;

        width: 42px;
        height: 24px;

        flex-shrink: 0;

        padding: 0;

        border: none;
        border-radius: 999px;

        background: #3a3a3a;

        transition: background 0.25s ease;
    }

    .switch:hover {
        background: #474747;
        border: none;
    }

    .switch[aria-checked="true"],
    .toggle input:checked + .switch-visual {
        background: #2f8f3a;
    }

    .knob {
        position: absolute;
        top: 3px;
        left: 3px;

        width: 18px;
        height: 18px;

        border-radius: 50%;

        background: white;

        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);

        transition: transform 0.25s cubic-bezier(0.34, 1.4, 0.64, 1);
    }

    .switch[aria-checked="true"] .knob,
    .toggle input:checked + .switch-visual .knob {
        transform: translateX(18px);
    }

    .estado-texto {
        color: var(--muted);

        font-size: 12px;
        font-weight: 500;
    }

    /* ==========================================
   ACCIONES
========================================== */

    .acciones {
        display: flex;
        justify-content: flex-end;
        gap: 8px;
    }

    .acciones button {
        padding: 7px 12px;

        font-size: 13px;
    }

    .vacio {
        padding: 50px 20px;

        text-align: center;

        color: var(--muted);
    }

    .vacio span {
        font-size: 32px;
    }

    .vacio p {
        margin: 10px 0 0;
    }

    /* ==========================================
   MODAL
========================================== */

    .modal {
        position: fixed;
        inset: 0;
        z-index: 1000;

        display: flex;
        align-items: center;
        justify-content: center;

        padding: 20px;
    }

    .modal-backdrop {
        position: absolute;
        inset: 0;

        padding: 0;

        border: none;
        border-radius: 0;

        background: rgba(0, 0, 0, 0.78);

        backdrop-filter: blur(5px);
        -webkit-backdrop-filter: blur(5px);

        cursor: default;

        animation: fadeIn 0.2s ease;
    }

    .modal-backdrop:hover {
        background: rgba(0, 0, 0, 0.78);
        border: none;
    }

    .modal-backdrop:active {
        transform: none;
    }

    .modal-content {
        position: relative;

        width: 100%;
        max-width: 580px;
        max-height: 92vh;

        display: flex;
        flex-direction: column;

        background: linear-gradient(145deg, #1b1b1b, #101010);

        border: 1px solid var(--gold-soft);
        border-radius: 18px;

        box-shadow: 0 25px 80px rgba(0, 0, 0, 0.7);

        overflow: hidden;

        animation: modalIn 0.3s cubic-bezier(0.22, 1, 0.36, 1);
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
        }
    }

    @keyframes modalIn {
        from {
            opacity: 0;
            transform: translateY(16px) scale(0.98);
        }
    }

    .modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;

        padding: 20px 24px;

        border-bottom: 1px solid var(--border);
    }

    .modal-header h2 {
        margin: 0;

        color: var(--gold);

        font-family: "Dela Gothic One", sans-serif;
        font-weight: 400;
        font-size: 22px;
    }

    .close {
        width: 36px;
        height: 36px;

        padding: 0;

        font-size: 22px;
        font-weight: 400;
    }

    .modal-body {
        display: flex;
        flex-direction: column;
        gap: 18px;

        padding: 22px 24px;

        overflow-y: auto;
    }

    /* ==========================================
   CAMPOS
========================================== */

    .modal-body label,
    legend {
        display: flex;
        flex-direction: column;
        gap: 7px;

        color: #ddd;

        font-size: 13px;
        font-weight: 700;
    }

    input,
    textarea,
    select {
        width: 100%;

        padding: 11px 13px;

        background: #0d0d0d;
        color: #eee;

        border: 1px solid #353535;
        border-radius: 9px;

        outline: none;

        font-family: inherit;
        font-size: 14px;
        font-weight: 400;

        transition:
            border-color 0.2s ease,
            box-shadow 0.2s ease;
    }

    input:focus,
    textarea:focus,
    select:focus {
        border-color: var(--gold);

        box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.12);
    }

    textarea {
        min-height: 100px;

        resize: vertical;

        line-height: 1.5;
    }

    input::placeholder,
    textarea::placeholder {
        color: #5f5f5f;
    }

    .dos-columnas {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 14px;
    }

    .input-precio {
        position: relative;
    }

    .input-precio span {
        position: absolute;
        left: 13px;
        top: 50%;

        transform: translateY(-50%);

        color: var(--muted);
    }

    .input-precio input {
        padding-left: 26px;

        font-variant-numeric: tabular-nums;
    }

    /* Nivel de picante */

    fieldset {
        margin: 0;
        padding: 0;

        border: none;
    }

    legend {
        margin-bottom: 8px;
        padding: 0;
    }

    .niveles {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 8px;
    }

    .nivel {
        flex-direction: column;
        gap: 4px;

        padding: 10px 6px;

        border: 1px solid var(--border);

        background: #0f0f0f;
        color: var(--muted);

        font-size: 12px;
        font-weight: 500;
    }

    .nivel-chiles {
        font-size: 12px;
        letter-spacing: -2px;
    }

    .nivel.selected {
        background: rgba(181, 28, 28, 0.14);
        border-color: var(--red-bright);
        color: #fff;
    }

    /* Imagen */

    .imagen-campo {
        display: grid;
        grid-template-columns: 88px 1fr;
        align-items: start;
        gap: 14px;
    }

    .preview {
        width: 88px;
        height: 88px;

        display: flex;
        align-items: center;
        justify-content: center;

        margin-top: 22px;

        border: 1px dashed #3a3a3a;
        border-radius: 12px;

        background: #0f0f0f;

        overflow: hidden;

        font-size: 26px;
    }

    .preview img {
        width: 100%;
        height: 100%;

        object-fit: cover;
    }

    .ayuda {
        color: var(--muted);

        font-size: 12px;
        font-weight: 400;
    }

    .ayuda.error {
        color: #ef7373;
    }

    /* Subir foto */

    .foto-acciones {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;

        min-width: 0;
    }

    .campo-titulo {
        color: #ddd;

        font-size: 13px;
        font-weight: 700;
    }

    .modal-body .btn-subir {
        flex-direction: row;
        align-items: center;
        gap: 8px;

        padding: 10px 16px;

        border: 1px solid var(--gold-soft);
        border-radius: 9px;

        background: rgba(212, 175, 55, 0.08);
        color: var(--gold);

        font-size: 14px;
        font-weight: 700;

        cursor: pointer;

        transition:
            background 0.2s ease,
            border-color 0.2s ease;
    }

    .modal-body .btn-subir:hover {
        background: rgba(212, 175, 55, 0.16);
        border-color: var(--gold);
    }

    .modal-body .btn-subir.disabled {
        opacity: 0.6;
        cursor: progress;
    }

    .btn-subir input {
        position: absolute;

        width: 1px;
        height: 1px;

        opacity: 0;
    }

    .btn-subir:focus-within {
        outline: 2px solid var(--gold);
        outline-offset: 2px;
    }

    .ruta-manual {
        width: 100%;

        color: var(--muted);

        font-size: 12px;
    }

    .ruta-manual summary {
        cursor: pointer;

        width: fit-content;
    }

    .ruta-manual summary:hover {
        color: #ccc;
    }

    .ruta-manual input {
        margin-top: 8px;
    }

    .preview.cargando {
        border-style: solid;
        border-color: var(--gold-soft);
    }

    .preview .spinner {
        width: 26px;
        height: 26px;

        border: 3px solid rgba(212, 175, 55, 0.25);
        border-top-color: var(--gold);
        border-radius: 50%;

        animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
        to {
            transform: rotate(360deg);
        }
    }

    /* Interruptor del formulario */

    .modal-body .toggle {
        flex-direction: row;
        align-items: center;
        gap: 14px;

        padding: 14px;

        border: 1px solid var(--border);
        border-radius: 12px;

        background: rgba(212, 175, 55, 0.04);

        cursor: pointer;
    }

    .toggle input {
        position: absolute;

        width: 1px;
        height: 1px;

        opacity: 0;
    }

    .toggle input:focus-visible + .switch-visual {
        outline: 2px solid var(--gold);
        outline-offset: 2px;
    }

    .toggle strong {
        display: block;

        color: #eee;

        font-size: 14px;
    }

    .toggle small {
        display: block;

        margin-top: 2px;

        color: var(--muted);

        font-size: 12px;
        font-weight: 400;
    }

    .modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 10px;

        padding: 16px 24px;

        border-top: 1px solid var(--border);

        background: #121212;
    }

    /* ==========================================
   AVISO (TOAST)
========================================== */

    .toast {
        position: fixed;
        left: 50%;
        bottom: 24px;
        z-index: 2000;

        display: flex;
        align-items: center;
        gap: 10px;

        max-width: calc(100vw - 32px);

        padding: 13px 18px;

        transform: translateX(-50%);

        border: 1px solid rgba(104, 196, 106, 0.4);
        border-radius: 12px;

        background: #142015;
        color: #d6f0d6;

        font-size: 14px;
        font-weight: 500;

        box-shadow: 0 12px 35px rgba(0, 0, 0, 0.5);

        animation: toastIn 0.35s cubic-bezier(0.22, 1, 0.36, 1);
    }

    .toast.error {
        border-color: rgba(220, 60, 60, 0.45);

        background: #241212;
        color: #f3c4c4;
    }

    @keyframes toastIn {
        from {
            opacity: 0;
            transform: translate(-50%, 12px);
        }
    }

    /* ==========================================
   SCROLLBAR
========================================== */

    ::-webkit-scrollbar {
        width: 8px;
        height: 8px;
    }

    ::-webkit-scrollbar-track {
        background: #0b0b0b;
    }

    ::-webkit-scrollbar-thumb {
        background: #3a3a3a;
        border-radius: 10px;
    }

    ::-webkit-scrollbar-thumb:hover {
        background: #555;
    }

    /* ==========================================
   TABLET
========================================== */

    @media (max-width: 1100px) {
        .fila {
            grid-template-columns: 56px minmax(0, 1fr) 110px 90px 120px 140px;
        }

        .fila > .picante,
        .fila-head > span:nth-child(5) {
            display: none;
        }
    }

    /* ==========================================
   CELULAR: LA LISTA SE VUELVE TARJETAS
========================================== */

    @media (max-width: 768px) {
        main {
            padding: 20px 16px 90px;
        }

        header {
            align-items: flex-start;
        }

        .brand img {
            width: 46px;
            height: 46px;
        }

        header h1 {
            font-size: 22px;
        }

        .header-actions {
            width: 100%;
        }

        .session {
            flex: 1 1 100%;
            max-width: none;
        }

        .header-actions .btn-ghost {
            flex: 1;
        }

        .stats {
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 10px;
        }

        .stat {
            padding: 14px;
        }

        .stat-value {
            font-size: 24px;
        }

        section {
            padding: 16px;
        }

        .section-header h2 {
            font-size: 19px;
        }

        .search {
            max-width: none;
            flex-basis: 100%;
        }

        .chips {
            flex-wrap: nowrap;

            overflow-x: auto;

            margin: 0 -16px;
            padding: 0 16px 4px;

            scrollbar-width: none;
        }

        .chip {
            flex-shrink: 0;
        }

        .lista {
            border: none;
            background: transparent;

            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .fila-head {
            display: none;
        }

        .fila {
            grid-template-columns: 64px minmax(0, 1fr) auto;
            grid-template-areas:
                "thumb info precio"
                "thumb cat  cat"
                "estado estado acciones";
            gap: 8px 12px;

            padding: 12px;

            border: 1px solid var(--border);
            border-radius: 12px;

            background: #111;
        }

        .fila:last-child {
            border-bottom: 1px solid var(--border);
        }

        .fila > .thumb {
            grid-area: thumb;

            width: 64px;
            height: 64px;
        }

        .fila > .info {
            grid-area: info;
        }

        .fila > .precio {
            grid-area: precio;
            align-self: start;
        }

        .fila > div:nth-child(3) {
            grid-area: cat;
        }

        .fila > .estado {
            grid-area: estado;

            padding-top: 4px;
        }

        .fila > .acciones {
            grid-area: acciones;

            padding-top: 4px;
        }

        .dos-columnas {
            grid-template-columns: 1fr;
        }

        .modal {
            align-items: flex-end;

            padding: 0;
        }

        .modal-content {
            max-width: none;
            max-height: 94vh;

            border-radius: 18px 18px 0 0;
        }

        .modal-header,
        .modal-body,
        .modal-actions {
            padding-left: 18px;
            padding-right: 18px;
        }

        .modal-actions button {
            flex: 1;
        }
    }

    /* ==========================================
   MENOS MOVIMIENTO SI EL USUARIO LO PREFIERE
========================================== */

    @media (prefers-reduced-motion: reduce) {
        .modal-content,
        .modal-backdrop,
        .toast {
            animation: none;
        }
    }
</style>
