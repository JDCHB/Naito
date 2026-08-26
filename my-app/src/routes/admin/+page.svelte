<script>
    import { onMount } from "svelte";
    import { supabase } from "$lib/supabase";
    import { goto } from "$app/navigation";

    let user = $state(null);

    let productos = $state([]);
    let categorias = $state([]);

    let loading = $state(true);
    let mensaje = $state("");

    // ==========================================
    // FORMULARIO
    // ==========================================

    let formularioAbierto = $state(false);
    let editando = $state(false);

    let productoId = $state(null);
    let nombre = $state("");
    let descripcion = $state("");
    let precio = $state("");
    let categoriaId = $state("");
    let imagenUrl = $state("");
    let activo = $state(true);
    let nivelPicante = $state(null);

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

            mensaje = "Error cargando categorías.";
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

            mensaje = "Error cargando productos.";
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

    // ==========================================
    // ABRIR FORMULARIO NUEVO
    // ==========================================

    function nuevoProducto() {
        editando = false;

        productoId = null;
        nombre = "";
        descripcion = "";
        precio = "";
        categoriaId = categorias.length > 0 ? categorias[0].id : "";
        imagenUrl = "";
        activo = true;
        nivelPicante = null;

        formularioAbierto = true;
    }

    // ==========================================
    // ABRIR FORMULARIO EDITAR
    // ==========================================

    function editarProducto(producto) {
        editando = true;

        productoId = producto.id;
        nombre = producto.nombre;
        descripcion = producto.descripcion;
        precio = producto.precio;
        categoriaId = producto.categoria_id;
        imagenUrl = producto.imagen_url ?? "";
        activo = producto.activo;
        nivelPicante = producto.nivel_picante ?? null;

        formularioAbierto = true;
    }

    // ==========================================
    // CERRAR FORMULARIO
    // ==========================================

    function cerrarFormulario() {
        formularioAbierto = false;
    }

    // ==========================================
    // GUARDAR PRODUCTO
    // ==========================================

    async function guardarProducto() {
        mensaje = "";

        if (!nombre.trim() || !descripcion.trim() || !precio || !categoriaId) {
            mensaje = "Completa todos los campos obligatorios.";
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

            if (error) {
                console.error("Error actualizando producto:", error);

                mensaje = "No se pudo actualizar el producto.";
                return;
            }

            productos = productos.map((p) => (p.id === productoId ? data : p));

            mensaje = "Producto actualizado correctamente.";
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

            if (error) {
                console.error("Error creando producto:", error);

                mensaje = "No se pudo crear el producto.";
                return;
            }

            productos = [...productos, data];

            mensaje = "Producto creado correctamente.";
        }

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

            mensaje = "No se pudo cambiar el estado.";
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

        mensaje = nuevoEstado ? "Producto activado." : "Producto desactivado.";
    }

    // ==========================================
    // ELIMINAR
    // ==========================================

    async function eliminarProducto(id) {
        const confirmar = confirm(
            "¿Seguro que quieres eliminar este producto?",
        );

        if (!confirmar) return;

        const { error } = await supabase
            .from("productos")
            .delete()
            .eq("id", id);

        if (error) {
            console.error("Error eliminando producto:", error);

            mensaje = "No se pudo eliminar el producto.";
            return;
        }

        productos = productos.filter((producto) => producto.id !== id);

        mensaje = "Producto eliminado correctamente.";
    }

    // ==========================================
    // CERRAR SESIÓN
    // ==========================================

    async function cerrarSesion() {
        await supabase.auth.signOut();

        goto("/admin/login");
    }
</script>

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
        <header>
            <div>
                <h1>Panel Administrativo</h1>

                <p>
                    Sesión:
                    <strong>{user.email}</strong>
                </p>
            </div>

            <button onclick={cerrarSesion}> Cerrar sesión </button>
        </header>

        {#if mensaje}
            <div class="mensaje">
                {mensaje}
            </div>
        {/if}

        <section>
            <div class="section-header">
                <h2>Productos</h2>

                <button class="btn-primary" onclick={nuevoProducto}>
                    + Nuevo producto
                </button>
            </div>

            <div class="tabla-container">
                <table>
                    <thead>
                        <tr>
                            <th>Producto</th>
                            <th>Precio</th>
                            <th>Categoría</th>
                            <th>Estado</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>

                    <tbody>
                        {#each productos as producto}
                            <tr>
                                <td>
                                    <strong>
                                        {producto.nombre}
                                    </strong>
                                </td>

                                <td>
                                    ${Number(producto.precio).toLocaleString(
                                        "es-CO",
                                    )}
                                </td>

                                <td>
                                    {obtenerCategoria(producto.categoria_id)}
                                </td>

                                <td>
                                    {#if producto.activo}
                                        <span class="activo"> ● Activo </span>
                                    {:else}
                                        <span class="inactivo">
                                            ● Inactivo
                                        </span>
                                    {/if}
                                </td>

                                <td class="acciones">
                                    <button
                                        onclick={() => cambiarEstado(producto)}
                                    >
                                        {producto.activo
                                            ? "Desactivar"
                                            : "Activar"}
                                    </button>

                                    <button
                                        onclick={() => editarProducto(producto)}
                                    >
                                        Editar
                                    </button>

                                    <button
                                        class="btn-danger"
                                        onclick={() =>
                                            eliminarProducto(producto.id)}
                                    >
                                        Eliminar
                                    </button>
                                </td>
                            </tr>
                        {/each}
                    </tbody>
                </table>
            </div>
        </section>

        {#if formularioAbierto}
            <div class="modal">
                <div class="modal-content">
                    <h2>
                        {editando ? "Editar producto" : "Nuevo producto"}
                    </h2>

                    <label>
                        Nombre

                        <input type="text" bind:value={nombre} />
                    </label>

                    <label>
                        Descripción

                        <textarea bind:value={descripcion}></textarea>
                    </label>

                    <label>
                        Precio

                        <input type="number" min="0" bind:value={precio} />
                    </label>

                    <label>
                        Categoría

                        <select bind:value={categoriaId}>
                            {#each categorias as categoria}
                                <option value={categoria.id}>
                                    {categoria.nombre}
                                </option>
                            {/each}
                        </select>
                    </label>

                    <label>
                        Nivel de picante

                        <select bind:value={nivelPicante}>
                            <option value={null}>No aplica</option>
                            <option value={1}>🌶️ Nivel 1 — Picante leve</option>
                            <option value={2}
                                >🌶️🌶️ Nivel 2 — Picante medio</option
                            >
                            <option value={3}
                                >🌶️🌶️🌶️ Nivel 3 — Picante fuerte</option
                            >
                            <option value={4}
                                >🌶️🌶️🌶️🌶️ Nivel 4 — Demasiado picante</option
                            >
                            <option value={5}
                                >🌶️🌶️🌶️🌶️🌶️ Nivel 5 — Super picante</option
                            >
                        </select>
                    </label>

                    <label>
                        URL de imagen

                        <input
                            type="text"
                            bind:value={imagenUrl}
                            placeholder="/Productos/imagen.jpg"
                        />
                    </label>

                    <label class="checkbox">
                        <input type="checkbox" bind:checked={activo} />

                        Producto activo
                    </label>

                    <div class="modal-actions">
                        <button onclick={cerrarFormulario}> Cancelar </button>

                        <button class="btn-primary" onclick={guardarProducto}>
                            {editando ? "Guardar cambios" : "Crear producto"}
                        </button>
                    </div>
                </div>
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
   ESTILO GENERAL
========================================== */

    :global(body) {
        margin: 0;
        background: radial-gradient(
                circle at top right,
                rgba(139, 0, 0, 0.12),
                transparent 35%
            ),
            radial-gradient(
                circle at bottom left,
                rgba(212, 175, 55, 0.06),
                transparent 30%
            ),
            #0d0d0d;

        color: #f5f1e8;
        font-family: Arial, Helvetica, sans-serif;
    }

    main {
        min-height: 100vh;
        padding: 40px;
        max-width: 1300px;
        margin: auto;
        box-sizing: border-box;
    }

    /* ==========================================
   HEADER
========================================== */

    header {
        display: flex;
        justify-content: space-between;
        align-items: center;

        padding-bottom: 25px;
        margin-bottom: 35px;

        border-bottom: 1px solid rgba(212, 175, 55, 0.25);
    }

    header h1 {
        margin: 0 0 8px;

        color: #d4af37;

        font-size: 32px;
        font-weight: 700;

        letter-spacing: 1px;
    }

    header p {
        margin: 0;

        color: #aaa;
        font-size: 14px;
    }

    header strong {
        color: #eee;
    }

    /* ==========================================
   BOTONES
========================================== */

    button {
        padding: 9px 16px;

        border: 1px solid transparent;
        border-radius: 7px;

        background: #242424;
        color: #eee;

        font-size: 14px;
        font-weight: 600;

        cursor: pointer;

        transition:
            background 0.2s ease,
            color 0.2s ease,
            border-color 0.2s ease,
            transform 0.2s ease;
    }

    button:hover {
        transform: translateY(-1px);

        background: #303030;
        border-color: #555;
    }

    /* ==========================================
   BOTÓN PRINCIPAL
========================================== */

    .btn-primary {
        background: #9d1515;
        color: #fff;

        border: 1px solid #b51c1c;

        box-shadow: 0 4px 15px rgba(150, 0, 0, 0.2);
    }

    .btn-primary:hover {
        background: #c21d1d;

        border-color: #d4af37;

        box-shadow: 0 5px 18px rgba(150, 0, 0, 0.35);
    }

    /* ==========================================
   MENSAJES
========================================== */

    .mensaje {
        padding: 14px 18px;

        margin-bottom: 25px;

        background: rgba(212, 175, 55, 0.08);

        border: 1px solid rgba(212, 175, 55, 0.35);

        border-left: 4px solid #d4af37;

        border-radius: 8px;

        color: #e8dcae;

        font-size: 14px;
    }

    /* ==========================================
   SECCIÓN PRODUCTOS
========================================== */

    section {
        background: #151515;

        border: 1px solid #292929;

        border-radius: 14px;

        padding: 25px;

        box-shadow: 0 10px 35px rgba(0, 0, 0, 0.35);
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;

        margin-bottom: 25px;
    }

    .section-header h2 {
        margin: 0;

        color: #f5f1e8;

        font-size: 22px;
    }

    /* ==========================================
   TABLA
========================================== */

    .tabla-container {
        overflow-x: auto;

        border: 1px solid #292929;

        border-radius: 10px;
    }

    table {
        width: 100%;

        border-collapse: collapse;

        background: #111;
    }

    th,
    td {
        padding: 16px;

        text-align: left;

        border-bottom: 1px solid #292929;
    }

    th {
        background: #1d1d1d;

        color: #d4af37;

        font-size: 13px;

        text-transform: uppercase;

        letter-spacing: 0.7px;
    }

    td {
        color: #d7d7d7;

        font-size: 14px;
    }

    tbody tr {
        transition: background 0.2s ease;
    }

    tbody tr:hover {
        background: rgba(212, 175, 55, 0.045);
    }

    tbody tr:last-child td {
        border-bottom: none;
    }

    td strong {
        color: #fff;
    }

    /* ==========================================
   ESTADOS
========================================== */

    .activo,
    .inactivo {
        display: inline-flex;

        align-items: center;

        gap: 5px;

        font-size: 13px;

        font-weight: 600;
    }

    .activo {
        color: #68c46a;
    }

    .inactivo {
        color: #888;
    }

    /* ==========================================
   ACCIONES
========================================== */

    .acciones {
        display: flex;

        gap: 7px;

        flex-wrap: wrap;
    }

    .acciones button {
        padding: 7px 11px;

        font-size: 12px;
    }

    /* ==========================================
   BOTÓN ELIMINAR
========================================== */

    .btn-danger {
        color: #e35d5d;

        background: rgba(180, 20, 20, 0.08);

        border: 1px solid rgba(180, 20, 20, 0.25);
    }

    .btn-danger:hover {
        color: white;

        background: #9d1515;

        border-color: #c21d1d;
    }

    /* ==========================================
   MODAL
========================================== */

    .modal {
        position: fixed;

        inset: 0;

        z-index: 1000;

        background: rgba(0, 0, 0, 0.78);

        backdrop-filter: blur(5px);

        display: flex;

        align-items: center;

        justify-content: center;

        padding: 20px;
    }

    /* ==========================================
   CONTENIDO DEL MODAL
========================================== */

    .modal-content {
        width: 100%;

        max-width: 520px;

        max-height: 90vh;

        overflow-y: auto;

        box-sizing: border-box;

        background: linear-gradient(145deg, #1b1b1b, #101010);

        border: 1px solid rgba(212, 175, 55, 0.25);

        border-radius: 16px;

        padding: 30px;

        display: flex;

        flex-direction: column;

        gap: 17px;

        box-shadow: 0 25px 80px rgba(0, 0, 0, 0.7);
    }

    .modal-content h2 {
        margin: 0 0 5px;

        color: #d4af37;

        font-size: 24px;
    }

    /* ==========================================
   CAMPOS
========================================== */

    .modal-content label {
        display: flex;

        flex-direction: column;

        gap: 7px;

        color: #ddd;

        font-size: 14px;

        font-weight: 600;
    }

    input,
    textarea,
    select {
        box-sizing: border-box;

        width: 100%;

        padding: 11px 13px;

        background: #0d0d0d;

        color: #eee;

        border: 1px solid #353535;

        border-radius: 7px;

        outline: none;

        font-family: inherit;

        font-size: 14px;

        transition:
            border-color 0.2s ease,
            box-shadow 0.2s ease;
    }

    input:focus,
    textarea:focus,
    select:focus {
        border-color: #d4af37;

        box-shadow: 0 0 0 2px rgba(212, 175, 55, 0.1);
    }

    textarea {
        min-height: 100px;

        resize: vertical;
    }

    input::placeholder {
        color: #666;
    }

    /* ==========================================
   CHECKBOX
========================================== */

    .checkbox {
        flex-direction: row !important;

        align-items: center;

        gap: 10px !important;

        padding: 10px;

        background: rgba(212, 175, 55, 0.05);

        border: 1px solid #292929;

        border-radius: 7px;
    }

    .checkbox input {
        width: auto;

        accent-color: #b51c1c;
    }

    /* ==========================================
   BOTONES DEL MODAL
========================================== */

    .modal-actions {
        display: flex;

        justify-content: flex-end;

        gap: 10px;

        margin-top: 10px;

        padding-top: 20px;

        border-top: 1px solid #292929;
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
   RESPONSIVE
========================================== */

    @media (max-width: 768px) {
        main {
            padding: 20px;
        }

        header {
            align-items: flex-start;

            gap: 15px;
        }

        header h1 {
            font-size: 25px;
        }

        .section-header {
            align-items: flex-start;

            gap: 15px;

            flex-direction: column;
        }

        section {
            padding: 15px;
        }

        th,
        td {
            padding: 12px 10px;
        }

        .acciones {
            flex-direction: column;
        }

        .acciones button {
            width: 100%;
        }

        .modal-content {
            padding: 22px;
        }
    }
</style>
