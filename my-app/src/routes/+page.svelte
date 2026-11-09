<script>
    import Sidebar from "$lib/components/Sidebar.svelte";

    import { onMount } from "svelte";
    import { supabase } from "$lib/supabase";

    let selectedCategory = $state("Ramens");

    // Productos que vienen de Supabase
    let products = $state([]);

    // Nombres de categorías que vienen de Supabase (para el menú)
    let categoryNames = $state([]);
    let categoryIcons = $state({});

    // Cargar categorías y productos
    onMount(async () => {
        // Obtener categorías
        const { data: categorias, error: categoriasError } = await supabase
            .from("categorias")
            .select("*")
            .order("id");

        if (categoriasError) {
            console.error("Error obteniendo categorías:", categoriasError);
            return;
        }

        categoryNames = categorias.map((categoria) => categoria.nombre);
        categoryIcons = Object.fromEntries(
            categorias.map((categoria) => [categoria.nombre, categoria.icono]),
        );

        // Si "Ramens" no existe, mostrar la primera categoría
        if (!categoryNames.includes(selectedCategory) && categoryNames.length > 0) {
            selectedCategory = categoryNames[0];
        }

        // Obtener productos
        const { data: productos, error: productosError } = await supabase
            .from("productos")
            .select("*");

        if (productosError) {
            console.error("Error obteniendo productos:", productosError);
            return;
        }

        // Convertir los datos de Supabase al formato que ya utiliza nuestro catálogo
        products = productos.map((producto) => {
            const categoria = categorias.find(
                (categoria) => categoria.id === producto.categoria_id,
            );

            return {
                id: producto.id,
                nombre: producto.nombre,
                descripcion: producto.descripcion ?? "",
                precio: producto.precio,
                imagen: producto.imagen_url ?? "",
                categoria: categoria?.nombre ?? "",
                activo: producto.activo,
                nivel_picante: producto.nivel_picante,
            };
        });

        cargado = true;
    });

    // Indica si ya terminaron de cargar los productos
    let cargado = $state(false);

    // Controla si el carrito está abierto o no
    let cartOpen = $state(false);

    // Productos que están dentro del carrito
    let cart = $state([]);

    function changeCategory(category) {
        selectedCategory = category;
    }

    // ==========================================
    // Aqui filtramos los productos por categoria
    let FiltrarProductos = $derived(
        products.filter(
            (product) =>
                product.categoria === selectedCategory &&
                product.activo === true,
        ),
    );

    // ==========================================
    // La imagen es una ruta local (/Productos/...) o una foto en la nube (https://...)
    function esImagen(imagen) {
        return /^(\/|https?:\/\/)/.test(imagen ?? "");
    }

    // ==========================================
    // Cuántas unidades de un producto hay en el carrito
    function cantidadEnCarrito(productId) {
        return cart.find((item) => item.id === productId)?.cantidad ?? 0;
    }

    // ==========================================
    // AGREGAR PRODUCTO AL CARRITO

    function addToCart(product) {
        const existingProduct = cart.find((item) => item.id === product.id);

        if (existingProduct) {
            existingProduct.cantidad += 1;
        } else {
            cart.push({
                ...product,
                cantidad: 1,
            });
        }
    }

    // ==========================================
    // AUMENTAR CANTIDAD

    function increaseQuantity(product) {
        product.cantidad += 1;
    }

    // ==========================================
    // DISMINUIR CANTIDAD

    function decreaseQuantity(product) {
        if (product.cantidad > 1) {
            product.cantidad -= 1;
        } else {
            removeFromCart(product.id);
        }
    }

    // ==========================================
    // ELIMINAR PRODUCTO

    function removeFromCart(productId) {
        const index = cart.findIndex((item) => item.id === productId);

        if (index !== -1) {
            cart.splice(index, 1);
        }
    }

    // ==========================================
    // VACIAR CARRITO

    function clearCart() {
        cart.splice(0, cart.length);
    }

    // ==========================================
    // CANTIDAD TOTAL DE PRODUCTOS

    let cartCount = $derived(
        cart.reduce((total, product) => total + product.cantidad, 0),
    );

    // ==========================================
    // TOTAL DEL CARRITO

    let cartTotal = $derived(
        cart.reduce(
            (total, product) => total + product.precio * product.cantidad,
            0,
        ),
    );

    // ==========================================
    // FORMATO DE PRECIO

    function formatPrice(price) {
        return `$${price.toLocaleString("es-CO")}`;
    }

    // ==========================================
    // REALIZAR EL PEDIDO WHATSAPP

    function realizarPedido() {
        if (cart.length === 0) return;

        let mensaje = `🍜 PEDIDO - Naito House

`;

        cart.forEach((product) => {
            const subtotal = product.precio * product.cantidad;

            mensaje += `${product.nombre}
Cantidad: ${product.cantidad}
Subtotal: ${formatPrice(subtotal)}

`;
        });

        mensaje += `--------------------
TOTAL: ${formatPrice(cartTotal)}

¡Hola!, quisiera realizar este pedido.`;

        const whatsappNumber = "573148287958";

        const url = `https://wa.me/${whatsappNumber}?text=${encodeURIComponent(mensaje)}`;

        window.open(url, "_blank");
    }

    // ==========================================
    // DESCRIPCIÓN DEL PRODUCTO

    let descripcionAbierta = $state(null);

    function toggleDescripcion(productId) {
        if (descripcionAbierta === productId) {
            descripcionAbierta = null;
        } else {
            descripcionAbierta = productId;
        }
    }
</script>

<Sidebar
    categorias={categoryNames}
    iconos={categoryIcons}
    activeCategory={selectedCategory}
    onCategoryChange={changeCategory}
/>

<svelte:head>
    <title>Naito House</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
    <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Dela+Gothic+One&family=Zen+Kaku+Gothic+New:wght@400;500;700;900&display=swap"
    />
</svelte:head>

<main class="content">
    {#if descripcionAbierta !== null}
        <button
            class="description-backdrop"
            aria-label="Cerrar descripción"
            onclick={() => (descripcionAbierta = null)}
        ></button>
    {/if}
    <section class="catalog">
        <!-- ENCABEZADO -->

        <div class="catalog-header">
            <div>
                <p class="small-title">NUESTROS PRODUCTOS</p>

                <h2>
                    {selectedCategory}
                </h2>

                {#if cargado}
                    <p class="count">
                        {FiltrarProductos.length}
                        {FiltrarProductos.length === 1 ? "producto" : "productos"}
                    </p>
                {/if}
            </div>

            <!-- CARRITO -->

            <button
                class="cart"
                aria-label="Abrir carrito"
                onclick={() => (cartOpen = true)}
            >
                🛒

                {#if cartCount > 0}
                    {#key cartCount}
                        <span>
                            {cartCount}
                        </span>
                    {/key}
                {/if}
            </button>
        </div>

        <!-- PRODUCTOS -->

        <div class="products">
            {#if !cargado}
                {#each [1, 2, 3, 4] as n (n)}
                    <div class="product-card skeleton" aria-hidden="true">
                        <div class="product-image"></div>
                        <div class="product-info">
                            <span class="sk-line sk-title"></span>
                            <span class="sk-line"></span>
                            <span class="sk-line sk-short"></span>
                        </div>
                    </div>
                {/each}
            {:else if FiltrarProductos.length === 0}
                <div class="empty-category">
                    <span>🍜</span>
                    <h3>Muy pronto</h3>
                    <p>Estamos preparando productos para esta categoría.</p>
                </div>
            {/if}

            {#each FiltrarProductos as product, i (product.id)}
                <article
                    class="product-card"
                    style="--i: {i}"
                    class:description-active={descripcionAbierta === product.id}
                    class:description-inactive={descripcionAbierta !== null &&
                        descripcionAbierta !== product.id}
                >
                    <!-- IMAGEN -->

                    <div class="product-image">
                        {#if esImagen(product.imagen)}
                            <img
                                src={product.imagen}
                                alt={product.nombre}
                                loading="lazy"
                                decoding="async"
                            />
                        {:else}
                            <span>{product.imagen}</span>
                        {/if}
                    </div>

                    <!-- INFORMACIÓN -->

                    <div class="product-info">
                        <h3>
                            {product.nombre}
                        </h3>

                        {#if product.nivel_picante !== null && product.nivel_picante !== undefined}
                            <div
                                class="spice-level"
                                aria-label="Picante nivel {product.nivel_picante} de 5"
                            >
                                <span class="spice-label">Picante</span>

                                {#each [1, 2, 3, 4, 5] as n}
                                    <span
                                        class="chili"
                                        class:on={n <= product.nivel_picante}
                                        aria-hidden="true">🌶️</span
                                    >
                                {/each}
                            </div>
                        {/if}

                        <button
                            class="description-button"
                            class:open={descripcionAbierta === product.id}
                            onclick={() => toggleDescripcion(product.id)}
                        >
                            {descripcionAbierta === product.id
                                ? "Ocultar descripción"
                                : "Ver descripción"}
                            <span class="chevron" aria-hidden="true">›</span>
                        </button>

                        {#if descripcionAbierta === product.id}
                            <div class="full-description">
                                <p>
                                    {product.descripcion}
                                </p>
                            </div>
                        {/if}

                        <div class="product-bottom">
                            <strong>
                                {formatPrice(product.precio)}
                            </strong>

                            <button
                                class="add"
                                class:in-cart={cantidadEnCarrito(product.id) > 0}
                                aria-label="Agregar {product.nombre} al carrito"
                                onclick={() => addToCart(product)}
                            >
                                {#if cantidadEnCarrito(product.id) > 0}
                                    ✓ {cantidadEnCarrito(product.id)} · +
                                {:else}
                                    + Agregar
                                {/if}
                            </button>
                        </div>
                    </div>
                </article>
            {/each}
        </div>
    </section>
</main>

<!-- BARRA FLOTANTE DEL PEDIDO -->

{#if cartCount > 0 && !cartOpen}
    <button class="order-bar" onclick={() => (cartOpen = true)}>
        <span class="order-bar-count">{cartCount}</span>
        <span class="order-bar-label">Ver mi pedido</span>
        <strong>{formatPrice(cartTotal)}</strong>
    </button>
{/if}

<!-- FONDO DEL CARRITO -->

{#if cartOpen}
    <button
        class="cart-overlay"
        aria-label="Cerrar carrito"
        onclick={() => (cartOpen = false)}
    ></button>

    <!-- PANEL DEL CARRITO -->

    <aside class="cart-panel">
        <!-- HEADER -->

        <div class="cart-header">
            <div>
                <p class="cart-small-title">TU PEDIDO</p>

                <h2>Mi carrito</h2>
            </div>

            <button class="close-cart" onclick={() => (cartOpen = false)}>
                ×
            </button>
        </div>

        <!-- PRODUCTOS DEL CARRITO -->

        {#if cart.length === 0}
            <div class="empty-cart">
                <div class="empty-icon">🛒</div>

                <h3>Tu carrito está vacío</h3>

                <p>Agrega algunos productos para comenzar tu pedido.</p>
            </div>
        {:else}
            <div class="cart-products">
                {#each cart as product}
                    <div class="cart-product">
                        <!-- IMAGEN -->

                        <div class="cart-product-image">
                            {#if esImagen(product.imagen)}
                                <img
                                    src={product.imagen}
                                    alt={product.nombre}
                                />
                            {:else}
                                <span>{product.imagen}</span>
                            {/if}
                        </div>

                        <!-- INFORMACIÓN -->

                        <div class="cart-product-info">
                            <h3>
                                {product.nombre}
                            </h3>

                            <strong>
                                {formatPrice(product.precio)}
                            </strong>

                            <!-- CONTROLES -->

                            <div class="quantity">
                                <button
                                    onclick={() => decreaseQuantity(product)}
                                >
                                    −
                                </button>

                                <span>
                                    {product.cantidad}
                                </span>

                                <button
                                    onclick={() => increaseQuantity(product)}
                                >
                                    +
                                </button>
                            </div>
                        </div>

                        <!-- ELIMINAR -->

                        <button
                            class="remove"
                            onclick={() => removeFromCart(product.id)}
                        >
                            ×
                        </button>
                    </div>
                {/each}
            </div>

            <!-- TOTAL -->

            <div class="cart-footer">
                <div class="total">
                    <span> Total </span>

                    <strong>
                        {formatPrice(cartTotal)}
                    </strong>
                </div>

                <button class="clear-cart" onclick={clearCart}>
                    Vaciar carrito
                </button>

                <button class="checkout" onclick={realizarPedido}>
                    Pedir por WhatsApp
                </button>
            </div>
        {/if}
    </aside>
{/if}

<style>
    /* =========================================================
       CONFIGURACIÓN GENERAL
    ========================================================= */

    :global(body) {
        margin: 0;

        font-family: "Zen Kaku Gothic New", Arial, Helvetica, sans-serif;

        color: #1b1b1b;

        -webkit-font-smoothing: antialiased;

        /* FONDO */
        /* Imagen sin bordes cortados: se repite sin que se note la unión */
        background-color: #323232;
        background-image: url("/Fondos/Fondo-gris-continuo.jpg");
        background-size: 190px 190px;
        background-position: 0 0;
        background-repeat: repeat;
    }

    :global(*) {
        box-sizing: border-box;
    }

    /* =========================================================
       CONTENIDO PRINCIPAL
    ========================================================= */

    .content {
        margin-left: 270px;

        padding: 35px 45px 110px;

        min-height: 100vh;
    }

    /* =========================================================
       ENCABEZADO DEL CATÁLOGO
    ========================================================= */

    .catalog-header {
        display: flex;

        justify-content: space-between;
        align-items: end;

        margin-bottom: 30px;

        padding-bottom: 22px;

        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }

    .catalog-header h2 {
        margin: 0;

        font-family: "Dela Gothic One", "Zen Kaku Gothic New", sans-serif;
        font-weight: 400;

        font-size: 40px;
        line-height: 1.1;

        color: white;

        text-shadow: 0 3px 18px rgba(0, 0, 0, 0.45);
    }

    .small-title {
        margin: 0 0 8px;

        display: flex;
        align-items: center;
        gap: 10px;

        color: #ff6b75;

        font-size: 11px;
        font-weight: 700;

        letter-spacing: 2.5px;
    }

    .small-title::before {
        content: "";

        width: 22px;
        height: 2px;

        border-radius: 2px;

        background: #e63946;
    }

    .count {
        margin: 8px 0 0;

        color: rgba(255, 255, 255, 0.6);

        font-size: 13px;
        font-weight: 500;
    }

    /* =========================================================
       BOTÓN DEL CARRITO
    ========================================================= */

    .cart {
        position: relative;

        width: 50px;
        height: 50px;

        border: none;
        border-radius: 12px;

        background: white;

        font-size: 22px;

        cursor: pointer;

        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);

        transition:
            transform 0.2s ease,
            box-shadow 0.2s ease;
    }

    .cart:hover {
        transform: translateY(-2px);

        box-shadow: 0 7px 20px rgba(0, 0, 0, 0.15);
    }

    .cart:active {
        transform: scale(0.95);
    }

    /* =========================================================
       Número de productos 
       ========================================================= */

    .cart span {
        position: absolute;

        top: -6px;
        right: -6px;

        min-width: 22px;
        height: 22px;

        padding: 0 6px;

        display: flex;
        align-items: center;
        justify-content: center;

        background: #e63946;
        color: white;

        border: 2px solid white;
        border-radius: 999px;

        font-size: 11px;
        font-weight: 700;
        font-variant-numeric: tabular-nums;

        animation: badgePop 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
    }

    @keyframes badgePop {
        from {
            transform: scale(0.4);
        }
        to {
            transform: scale(1);
        }
    }

    /* =========================================================
       LISTA DE PRODUCTOS
    ========================================================= */

    .products {
        display: grid;

        /* PC: 2 productos por fila */
        grid-template-columns: repeat(2, minmax(0, 1fr));

        gap: 24px;
    }

    /* =========================================================
       TARJETA DEL PRODUCTO
    ========================================================= */

    .product-card {
        width: 100%;
        min-height: 190px;

        display: flex;

        background: #fffdf9;

        border-radius: 18px;
        border: 1px solid rgba(255, 255, 255, 0.6);

        overflow: hidden;

        box-shadow:
            0 1px 2px rgba(0, 0, 0, 0.12),
            0 10px 30px rgba(0, 0, 0, 0.28);

        position: relative;
        z-index: 1;

        /* Entrada escalonada de las tarjetas */
        animation: cardIn 0.5s cubic-bezier(0.22, 1, 0.36, 1) backwards;
        animation-delay: calc(var(--i, 0) * 70ms);

        transition:
            transform 0.35s ease,
            box-shadow 0.35s ease,
            filter 0.35s ease,
            opacity 0.35s ease;
    }

    @keyframes cardIn {
        from {
            opacity: 0;
            transform: translateY(14px);
        }
    }

    .product-card:hover {
        transform: translateY(-4px);

        box-shadow:
            0 0 0 2px rgba(230, 57, 70, 0.55),
            0 18px 40px rgba(0, 0, 0, 0.35);
    }

    /* Alternar imagen: INFO | IMAGEN, IMAGEN | INFO... */

    .product-card:nth-child(even) {
        flex-direction: row-reverse;
    }

    /* =========================================================
       IMAGEN DEL PRODUCTO
    ========================================================= */

    .product-image {
        width: 36%;
        min-height: 190px;

        flex-shrink: 0;

        display: flex;
        align-items: center;
        justify-content: center;

        background: #eee9e2;

        overflow: hidden;

        position: relative;
    }

    .product-image img {
        position: absolute;
        inset: 0;

        width: 100%;
        height: 100%;

        display: block;

        object-fit: cover;

        transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
    }

    .product-card:hover .product-image img {
        transform: scale(1.06);
    }

    /* Para productos que usan un emoji en vez de imagen */
    .product-image span {
        font-size: 55px;
    }

    /* =========================================================
       INFORMACIÓN DEL PRODUCTO
    ========================================================= */

    .product-info {
        flex: 1;
        min-width: 0;

        padding: 22px 22px 20px;

        display: flex;
        flex-direction: column;
        justify-content: center;
    }

    .product-info h3 {
        margin: 0 0 10px;

        font-size: 19px;
        font-weight: 900;
        line-height: 1.25;

        color: #1b1b1b;

        text-wrap: balance;
    }

    .product-info p {
        max-width: 300px;

        margin: 0 0 18px;

        color: #777;

        font-size: 13px;
        line-height: 1.5;
    }

    /* =========================================================
       PRECIO + BOTÓN AGREGAR
    ========================================================= */

    .product-bottom {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 10px;

        margin-top: auto;
        padding-top: 14px;

        border-top: 1px dashed #e7e1d8;
    }

    .product-bottom strong {
        font-size: 21px;
        font-weight: 900;
        font-variant-numeric: tabular-nums;

        color: #1b1b1b;
    }

    /* =========================================================
       BOTÓN AGREGAR
    ========================================================= */

    .add {
        height: 38px;

        padding: 0 16px;

        border: none;
        border-radius: 10px;

        background: #e63946;
        color: white;

        font-family: inherit;
        font-size: 14px;
        font-weight: 700;
        white-space: nowrap;

        cursor: pointer;

        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;

        box-shadow: 0 4px 12px rgba(230, 57, 70, 0.3);

        transition:
            transform 0.2s ease,
            background 0.2s ease,
            box-shadow 0.2s ease;
    }

    .add:hover {
        background: #c92f3b;

        transform: translateY(-1px);

        box-shadow: 0 7px 18px rgba(230, 57, 70, 0.4);
    }

    .add:active {
        transform: scale(0.96);
    }

    /* Cuando el producto ya está en el carrito */
    .add.in-cart {
        background: #1b1b1b;

        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
    }

    .add.in-cart:hover {
        background: #333;
    }

    /* =========================================================
       FONDO OSCURO DEL CARRITO
    ========================================================= */

    .cart-overlay {
        position: fixed;

        inset: 0;

        width: 100%;
        height: 100%;

        padding: 0;

        border: none;

        background: rgba(0, 0, 0, 0.55);

        cursor: pointer;

        z-index: 999;
    }

    /* =========================================================
       PANEL DEL CARRITO
    ========================================================= */

    .cart-panel {
        position: fixed;

        top: 0;
        right: 0;

        width: 400px;
        max-width: 90vw;

        height: 100vh;

        display: flex;

        flex-direction: column;

        background: white;

        z-index: 1000;

        box-shadow: -10px 0 30px rgba(0, 0, 0, 0.25);

        animation: slideCart 0.25s ease;
    }

    /* =========================================================
       Animación de entrada 
       ========================================================= */

    @keyframes slideCart {
        from {
            transform: translateX(100%);
        }

        to {
            transform: translateX(0);
        }
    }

    /* =========================================================
       HEADER DEL CARRITO
    ========================================================= */

    .cart-header {
        display: flex;

        align-items: center;

        justify-content: space-between;

        padding: 25px;

        border-bottom: 1px solid #eeeeee;
    }

    .cart-small-title {
        margin: 0 0 5px;

        color: #e63946;

        font-size: 11px;

        font-weight: bold;

        letter-spacing: 1.5px;
    }

    .cart-header h2 {
        margin: 0;

        color: #1b1b1b;

        font-size: 25px;
    }

    /* =========================================================
       BOTÓN CERRAR CARRITO
    ========================================================= */

    .close-cart {
        width: 38px;
        height: 38px;

        border: none;

        border-radius: 10px;

        background: #f1f1f1;

        color: #333;

        font-size: 25px;

        cursor: pointer;

        display: flex;

        align-items: center;
        justify-content: center;

        transition:
            background 0.2s ease,
            color 0.2s ease;
    }

    .close-cart:hover {
        background: #e63946;

        color: white;
    }

    /* =========================================================
       CARRITO VACÍO
    ========================================================= */

    .empty-cart {
        flex: 1;

        display: flex;

        flex-direction: column;

        align-items: center;

        justify-content: center;

        text-align: center;

        padding: 30px;
    }

    .empty-icon {
        margin-bottom: 15px;

        font-size: 55px;
    }

    .empty-cart h3 {
        margin: 0 0 8px;

        color: #1b1b1b;

        font-size: 19px;
    }

    .empty-cart p {
        max-width: 260px;

        margin: 0;

        color: #888;

        font-size: 13px;

        line-height: 1.5;
    }

    /* =========================================================
       PRODUCTOS DENTRO DEL CARRITO
    ========================================================= */

    .cart-products {
        flex: 1;

        padding: 20px;

        overflow-y: auto;

        /*
         * Ocultar scrollbar
         */
        scrollbar-width: none;
    }

    .cart-products::-webkit-scrollbar {
        display: none;
    }

    /* =========================================================
       PRODUCTO DEL CARRITO
    ========================================================= */

    .cart-product {
        position: relative;

        display: flex;

        align-items: center;

        gap: 12px;

        padding: 12px;

        margin-bottom: 12px;

        border-radius: 12px;

        background: #f7f7f7;
    }

    /* =========================================================
       Imagen del producto
       ========================================================= */

    .cart-product-image {
        width: 70px;
        height: 70px;

        flex-shrink: 0;

        overflow: hidden;

        border-radius: 10px;

        background: #eee9e2;

        display: flex;

        align-items: center;
        justify-content: center;
    }

    .cart-product-image img {
        width: 100%;
        height: 100%;

        display: block;

        object-fit: cover;
    }

    .cart-product-image span {
        font-size: 35px;
    }

    /* Información */

    .cart-product-info {
        flex: 1;

        min-width: 0;
    }

    .cart-product-info h3 {
        margin: 0 0 5px;

        color: #1b1b1b;

        font-size: 14px;
    }

    .cart-product-info strong {
        display: block;

        margin-bottom: 8px;

        color: #e63946;

        font-size: 14px;
    }

    /* =========================================================
       CONTROL DE CANTIDAD
    ========================================================= */

    .quantity {
        display: flex;

        align-items: center;

        gap: 8px;
    }

    .quantity button {
        width: 25px;
        height: 25px;

        padding: 0;

        border: none;

        border-radius: 6px;

        background: #e63946;

        color: white;

        font-size: 16px;

        cursor: pointer;

        display: flex;

        align-items: center;
        justify-content: center;

        transition:
            background 0.2s ease,
            transform 0.2s ease;
    }

    .quantity button:hover {
        background: #c92f3b;
    }

    .quantity button:active {
        transform: scale(0.9);
    }

    .quantity span {
        min-width: 20px;

        text-align: center;

        color: #1b1b1b;

        font-size: 13px;

        font-weight: bold;
    }

    /* =========================================================
       BOTÓN ELIMINAR
    ========================================================= */

    .remove {
        position: absolute;

        top: 7px;
        right: 7px;

        border: none;

        background: transparent;

        color: #999;

        font-size: 18px;

        line-height: 1;

        cursor: pointer;

        transition: color 0.2s ease;
    }

    .remove:hover {
        color: #e63946;
    }

    /* =========================================================
       FOOTER DEL CARRITO
    ========================================================= */

    .cart-footer {
        padding: 20px;

        border-top: 1px solid #eeeeee;

        background: white;
    }

    /* TOTAL */

    .total {
        display: flex;

        align-items: center;

        justify-content: space-between;

        margin-bottom: 15px;

        color: #333;

        font-size: 16px;
    }

    .total strong {
        color: #1b1b1b;

        font-size: 20px;
    }

    /* =========================================================
       BOTÓN VACIAR CARRITO
    ========================================================= */

    .clear-cart {
        width: 100%;

        padding: 11px;

        margin-bottom: 10px;

        border: 1px solid #ddd;

        border-radius: 9px;

        background: white;

        color: #555;

        font-size: 13px;

        cursor: pointer;

        transition:
            background 0.2s ease,
            border-color 0.2s ease;
    }

    .clear-cart:hover {
        background: #f5f5f5;

        border-color: #ccc;
    }

    /* =========================================================
       BOTÓN REALIZAR PEDIDO
    ========================================================= */

    .checkout {
        width: 100%;

        padding: 13px;

        border: none;

        border-radius: 9px;

        background: #e63946;

        color: white;

        font-size: 15px;

        font-weight: bold;

        cursor: pointer;

        transition:
            background 0.2s ease,
            transform 0.2s ease;
    }

    .checkout:hover {
        background: #c92f3b;

        transform: translateY(-1px);
    }

    /* =========================================================
       TABLETS
    ========================================================= */

    @media (max-width: 1000px) {
        .content {
            margin-left: 220px;

            padding: 30px 30px 110px;
        }

        /*
         * En tablet dejamos un producto
         * por fila para que las tarjetas
         * tengan suficiente espacio.
         */

        .products {
            grid-template-columns: 1fr;
        }

        .product-card {
            min-height: 180px;
        }

        .product-image {
            width: 34%;

            min-height: 180px;
        }
    }

    /* =========================================================
       TABLETS PEQUEÑAS / MÓVILES
    ========================================================= */

    @media (max-width: 750px) {
        .content {
            margin-left: 0;

            padding: 90px 20px 110px;
        }

        .catalog-header {
            margin-bottom: 25px;
        }

        .catalog-header h2 {
            font-size: 26px;
        }

        .products {
            grid-template-columns: 1fr;

            gap: 18px;
        }

        .product-card {
            min-height: 170px;
        }

        .product-image {
            width: 36%;

            min-height: 170px;
        }

        .product-info {
            padding: 20px;
        }

        .product-info h3 {
            font-size: 18px;
        }

        .product-info p {
            font-size: 13px;
        }

        /*
         * Carrito en móvil
         */

        .cart-panel {
            width: 100%;

            max-width: 100%;
        }
    }

    /* =========================================================
       CELULARES
    ========================================================= */

    @media (max-width: 550px) {
        .content {
            padding: 85px 15px 110px;
        }

        .catalog-header h2 {
            font-size: 23px;
        }

        .small-title {
            font-size: 10px;
        }

        .cart {
            width: 45px;
            height: 45px;

            font-size: 19px;
        }

        .product-card {
            min-height: 150px;

            border-radius: 14px;
        }

        .product-image {
            width: 38%;

            min-height: 160px;
        }

        .product-info {
            padding: 15px;
        }

        .product-info h3 {
            margin-bottom: 6px;

            font-size: 16px;
        }

        .product-info p {
            margin-bottom: 12px;

            font-size: 12px;

            line-height: 1.4;
        }

        .product-bottom strong {
            font-size: 15px;
        }

        .add {
            height: 34px;

            padding: 0 12px;

            font-size: 13px;
        }

        /* -------------------------
           CARRITO EN CELULAR
        ------------------------- */

        .cart-header {
            padding: 20px;
        }

        .cart-header h2 {
            font-size: 22px;
        }

        .cart-products {
            padding: 15px;
        }

        .cart-footer {
            padding: 15px;
        }

        .cart-product-image {
            width: 60px;
            height: 60px;
        }

        .cart-product-info h3 {
            font-size: 13px;
        }

        .cart-product-info strong {
            font-size: 13px;
        }
    }

    /* =========================================================
       CELULARES MUY PEQUEÑOS
    ========================================================= */

    @media (max-width: 380px) {
        .content {
            padding-left: 10px;

            padding-right: 10px;
        }

        .catalog-header h2 {
            font-size: 21px;
        }

        .product-card {
            min-height: 140px;
        }

        .product-image {
            width: 38%;

            min-height: 150px;
        }

        .product-info {
            padding: 12px;
        }

        .product-info h3 {
            font-size: 15px;
        }

        .product-info p {
            margin-bottom: 9px;

            font-size: 11px;
        }

        .product-bottom strong {
            font-size: 14px;
        }

        .add {
            height: 32px;

            padding: 0 10px;

            font-size: 12px;
        }

        /* Carrito */

        .cart-product {
            gap: 8px;

            padding: 10px;
        }

        .cart-product-image {
            width: 55px;
            height: 55px;
        }

        .cart-product-info h3 {
            font-size: 12px;
        }

        .cart-product-info strong {
            font-size: 12px;
        }
    }

    /* =========================================================
       TEXTO DEL NIVEL PICANTE
    ========================================================= */
    .spice-level {
        display: flex;
        align-items: center;
        gap: 2px;

        margin: 0 0 8px;
    }

    .spice-label {
        margin-right: 6px;

        padding: 2px 8px;

        border-radius: 999px;

        background: #fdecee;
        color: #b91c1c;

        font-size: 10px;
        font-weight: 700;
        letter-spacing: 1px;
        text-transform: uppercase;
    }

    .chili {
        font-size: 13px;
        line-height: 1;

        filter: grayscale(1);
        opacity: 0.25;
    }

    .chili.on {
        filter: none;
        opacity: 1;
    }

    /* =========================================================
       BOTÓN VER DESCRIPCIÓN
    ========================================================= */

    .description-button {
        align-self: flex-start;

        display: inline-flex;
        align-items: center;
        gap: 4px;

        border: none;
        background: transparent;
        padding: 0;
        margin: 2px 0 12px;

        color: #b91c1c;

        font-family: inherit;
        font-size: 0.85rem;
        font-weight: 700;

        cursor: pointer;
        text-align: left;

        transition: color 0.2s ease;
    }

    .description-button:hover {
        color: #e63946;
    }

    .chevron {
        display: inline-block;

        font-size: 1.1rem;
        line-height: 1;

        transition: transform 0.25s ease;
    }

    .description-button:hover .chevron {
        transform: translateX(2px);
    }

    .description-button.open .chevron {
        transform: rotate(90deg);
    }

    /* ==========================================
   DESCRIPCIÓN DEL PRODUCTO
========================================== */

    /* Tarjeta seleccionada */

    .product-card.description-active {
        z-index: 100;

        animation: cardBounce 0.55s ease forwards;
    }

    /* Resto de tarjetas */

    .product-card.description-inactive {
        filter: blur(5px);
        opacity: 0.3;
        transform: scale(0.98);
    }

    /* ==========================================
   ANIMACIÓN BOUNCE
========================================== */

    @keyframes cardBounce {
        0% {
            transform: scale(1);
        }

        30% {
            transform: translateY(-18px) scale(1.04);
        }

        50% {
            transform: translateY(5px) scale(1.02);
        }

        70% {
            transform: translateY(-4px) scale(1.03);
        }

        100% {
            transform: translateY(0) scale(1.03);
        }
    }

    /* ==========================================
   DESCRIPCIÓN
========================================== */

    .full-description {
        margin-top: 12px;

        animation: descriptionAppear 0.3s ease;
    }

    .full-description p {
        margin: 0;

        color: #333;
        font-size: 0.9rem;
        line-height: 1.6;
    }

    @keyframes descriptionAppear {
        from {
            opacity: 0;
            transform: translateY(-8px);
        }

        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    /* ==========================================
   FONDO DE DESCRIPCIÓN
========================================== */

    .description-backdrop {
        position: fixed;
        inset: 0;

        z-index: 50;

        width: 100%;
        height: 100%;

        border: none;

        background: rgba(0, 0, 0, 0.45);

        backdrop-filter: blur(7px);
        -webkit-backdrop-filter: blur(7px);

        cursor: default;

        animation: backdropAppear 0.3s ease;
    }

    @keyframes backdropAppear {
        from {
            opacity: 0;
        }

        to {
            opacity: 1;
        }
    }
    /* =========================================================
       CATEGORÍA SIN PRODUCTOS
    ========================================================= */

    .empty-category {
        grid-column: 1 / -1;

        padding: 60px 20px;

        text-align: center;

        border: 1px dashed rgba(255, 255, 255, 0.2);
        border-radius: 18px;

        background: rgba(0, 0, 0, 0.35);

        color: white;
    }

    .empty-category span {
        font-size: 44px;
    }

    .empty-category h3 {
        margin: 10px 0 6px;

        font-family: "Dela Gothic One", sans-serif;
        font-weight: 400;
        font-size: 22px;
    }

    .empty-category p {
        margin: 0;

        color: rgba(255, 255, 255, 0.65);

        font-size: 14px;
    }

    /* =========================================================
       TARJETAS DE CARGA (SKELETON)
    ========================================================= */

    .product-card.skeleton {
        animation: none;
    }

    .product-card.skeleton:hover {
        transform: none;
    }

    .skeleton .product-image,
    .sk-line {
        background: linear-gradient(90deg, #eee9e2 25%, #f7f3ee 50%, #eee9e2 75%);
        background-size: 200% 100%;

        animation: shimmer 1.3s linear infinite;
    }

    .sk-line {
        display: block;

        height: 12px;
        width: 70%;

        margin-bottom: 12px;

        border-radius: 6px;
    }

    .sk-title {
        height: 18px;
        width: 85%;
    }

    .sk-short {
        width: 40%;
        margin-top: 18px;
    }

    @keyframes shimmer {
        to {
            background-position: -200% 0;
        }
    }

    /* =========================================================
       BARRA FLOTANTE "VER MI PEDIDO"
    ========================================================= */

    .order-bar {
        position: fixed;

        right: 30px;
        bottom: 26px;

        z-index: 900;

        display: flex;
        align-items: center;
        gap: 12px;

        padding: 10px 12px 10px 10px;

        border: none;
        border-radius: 999px;

        background: #e63946;
        color: white;

        font-family: inherit;
        font-size: 15px;

        cursor: pointer;

        box-shadow:
            0 10px 30px rgba(230, 57, 70, 0.45),
            0 2px 6px rgba(0, 0, 0, 0.3);

        animation: barIn 0.4s cubic-bezier(0.22, 1, 0.36, 1);

        transition:
            transform 0.2s ease,
            background 0.2s ease;
    }

    .order-bar:hover {
        background: #c92f3b;

        transform: translateY(-2px);
    }

    .order-bar-count {
        min-width: 32px;
        height: 32px;

        padding: 0 8px;

        display: flex;
        align-items: center;
        justify-content: center;

        border-radius: 999px;

        background: white;
        color: #e63946;

        font-weight: 900;
        font-variant-numeric: tabular-nums;
    }

    .order-bar-label {
        font-weight: 700;
    }

    .order-bar strong {
        padding-left: 12px;

        border-left: 1px solid rgba(255, 255, 255, 0.35);

        font-weight: 900;
        font-variant-numeric: tabular-nums;
    }

    @keyframes barIn {
        from {
            opacity: 0;
            transform: translateY(20px);
        }
    }

    @media (max-width: 750px) {
        .order-bar {
            left: 16px;
            right: 16px;
            bottom: max(16px, env(safe-area-inset-bottom));

            justify-content: space-between;
        }

        .order-bar-label {
            flex: 1;
            text-align: left;
        }
    }

    /* =========================================================
       FOCO VISIBLE (TECLADO)
    ========================================================= */

    button:focus-visible {
        outline: 3px solid #ffb4ba;
        outline-offset: 2px;
    }

    /* =========================================================
       MENOS MOVIMIENTO SI EL USUARIO LO PREFIERE
    ========================================================= */

    @media (prefers-reduced-motion: reduce) {
        .product-card,
        .order-bar,
        .cart span,
        .skeleton .product-image,
        .sk-line {
            animation: none;
        }
    }
</style>
