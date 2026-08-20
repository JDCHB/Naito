<script>
    import Sidebar from "$lib/components/Sidebar.svelte";

    let selectedCategory = $state("Ramens");

    // Controla si el carrito está abierto o no
    let cartOpen = $state(false);

    // Productos que están dentro del carrito
    let cart = $state([]);

    function changeCategory(category) {
        selectedCategory = category;
    }

    const products = [
        {
            id: 1,
            nombre: "Tonkotsu Ramen",
            descripcion: "Caldo cremoso de cerdo con huevo y cebollín.",
            precio: 28000,
            imagen: "/Productos/Tonkotsu_Ramen.jpg",
            categoria: "Ramens",
        },
        {
            id: 2,
            nombre: "Shoyu Ramen",
            descripcion: "Caldo tradicional de soja con cerdo y vegetales.",
            precio: 26000,
            imagen: "/Productos/Shoyu_Ramen.jpg",
            categoria: "Ramens",
        },
        {
            id: 3,
            nombre: "Miso Ramen",
            descripcion: "Caldo de miso con maíz y huevo.",
            precio: 27000,
            imagen: "/Productos/Miso_Ramen.jpg",
            categoria: "Ramens",
        },

        // BEBIDAS

        {
            id: 4,
            nombre: "Matcha Latte",
            descripcion: "Deliciosa bebida de matcha con leche.",
            precio: 12000,
            imagen: "/Productos/Payasito.jpg",
            categoria: "Bebidas",
        },
        {
            id: 5,
            nombre: "Té Verde Japonés",
            descripcion: "Té verde japonés tradicional.",
            precio: 8000,
            imagen: "/Productos/Payasito.jpg",
            categoria: "Bebidas",
        },
        {
            id: 6,
            nombre: "Ramune",
            descripcion: "Refresco japonés tradicional.",
            precio: 10000,
            imagen: "/Productos/Payasito.jpg",
            categoria: "Bebidas",
        },

        // SNACKS

        {
            id: 7,
            nombre: "Gyozas",
            descripcion: "Gyozas japonesas rellenas de cerdo.",
            precio: 15000,
            imagen: "/Productos/Payasito.jpg",
            categoria: "Snacks",
        },
        {
            id: 8,
            nombre: "Edamame",
            descripcion: "Edamame japonés ligeramente salado.",
            precio: 10000,
            imagen: "/Productos/Payasito.jpg",
            categoria: "Snacks",
        },
        {
            id: 9,
            nombre: "Takoyaki",
            descripcion: "Tradicionales bolitas japonesas de pulpo.",
            precio: 18000,
            imagen: "/Productos/Payasito.jpg",
            categoria: "Snacks",
        },
    ];

    let FiltrarProductos = $derived(
        products.filter((product) => product.categoria === selectedCategory),
    );

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

        let mensaje = `🍜 PEDIDO - NAITO HOUSE

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

¡Hola! Quisiera realizar este pedido.`;

        const whatsappNumber = "573148287958";

        const url = `https://wa.me/${whatsappNumber}?text=${encodeURIComponent(mensaje)}`;

        window.open(url, "_blank");
    }
</script>

<Sidebar onCategoryChange={changeCategory} />

<main class="content">
    <section class="catalog">
        <!-- ENCABEZADO -->

        <div class="catalog-header">
            <div>
                <p class="small-title">NUESTROS PRODUCTOS</p>

                <h2>
                    {selectedCategory}
                </h2>
            </div>

            <!-- CARRITO -->

            <button class="cart" onclick={() => (cartOpen = true)}>
                🛒

                {#if cartCount > 0}
                    <span>
                        {cartCount}
                    </span>
                {/if}
            </button>
        </div>

        <!-- PRODUCTOS -->

        <div class="products">
            {#each FiltrarProductos as product}
                <article class="product-card">
                    <!-- IMAGEN -->

                    <div class="product-image">
                        {#if product.imagen.startsWith("/")}
                            <img src={product.imagen} alt={product.nombre} />
                        {:else}
                            <span>{product.imagen}</span>
                        {/if}
                    </div>

                    <!-- INFORMACIÓN -->

                    <div class="product-info">
                        <h3>
                            {product.nombre}
                        </h3>

                        <p>
                            {product.descripcion}
                        </p>

                        <div class="product-bottom">
                            <strong>
                                {formatPrice(product.precio)}
                            </strong>

                            <button
                                class="add"
                                onclick={() => addToCart(product)}
                            >
                                +
                            </button>
                        </div>
                    </div>
                </article>
            {/each}
        </div>
    </section>
</main>

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
                            {#if product.imagen.startsWith("/")}
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
                    Realizar pedido
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

        font-family: Arial, Helvetica, sans-serif;

        color: #1b1b1b;

        /* FONDO */
        background-image: url("Fondos/Fondo-gris.jpeg");
        background-size: 350px 350px;
        background-position: center;
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

        padding: 35px 45px;

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
    }

    .catalog-header h2 {
        margin: 0;

        font-size: 30px;

        color: white;
    }

    .small-title {
        margin: 0 0 6px;

        color: #e63946;

        font-size: 11px;
        font-weight: bold;

        letter-spacing: 1.5px;
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

    /* Número de productos */

    .cart span {
        position: absolute;

        top: -5px;
        right: -5px;

        width: 20px;
        height: 20px;

        display: flex;

        align-items: center;
        justify-content: center;

        background: #e63946;

        color: white;

        border-radius: 50%;

        font-size: 11px;
        font-weight: bold;
    }

    /* =========================================================
       LISTA DE PRODUCTOS
    ========================================================= */

    .products {
        display: grid;

        /*
         * PC:
         * 2 productos por fila
         */
        grid-template-columns: repeat(2, minmax(0, 1fr));

        gap: 22px;
    }

    /* =========================================================
       TARJETA DEL PRODUCTO
    ========================================================= */

    .product-card {
        width: 100%;

        min-height: 180px;

        display: flex;

        background: rgba(255, 255, 255, 0.96);

        border-radius: 16px;

        overflow: hidden;

        box-shadow: 0 5px 20px rgba(0, 0, 0, 0.08);

        transition:
            transform 0.25s ease,
            box-shadow 0.25s ease;
    }

    .product-card:hover {
        transform: translateY(-4px);

        box-shadow: 0 12px 30px rgba(0, 0, 0, 0.15);
    }

    /* =========================================================
       ALTERNAR IMAGEN

       Producto 1:
       INFORMACIÓN | IMAGEN

       Producto 2:
       IMAGEN | INFORMACIÓN

       Producto 3:
       INFORMACIÓN | IMAGEN

       Producto 4:
       IMAGEN | INFORMACIÓN
    ========================================================= */

    .product-card:nth-child(even) {
        flex-direction: row-reverse;
    }

    /* =========================================================
       IMAGEN DEL PRODUCTO
    ========================================================= */

    .product-image {
        width: 27%;

        min-height: 180px;

        flex-shrink: 0;

        display: flex;

        align-items: center;
        justify-content: center;

        background: #eee9e2;

        overflow: hidden;
    }

    .product-image img {
        width: 100%;
        height: 100%;

        display: block;

        /*
         * La imagen ocupa solamente
         * el espacio destinado a ella.
         */
        object-fit: cover;

        transition: transform 0.4s ease;
    }

    .product-card:hover .product-image img {
        transform: scale(1.04);
    }

    /* Para cuando todavía tengas algún producto
       usando un emoji */

    .product-image span {
        font-size: 55px;
    }

    /* =========================================================
       INFORMACIÓN DEL PRODUCTO
    ========================================================= */

    .product-info {
        flex: 1;

        min-width: 0;

        padding: 22px;

        display: flex;

        flex-direction: column;

        justify-content: center;
    }

    .product-info h3 {
        margin: 0 0 8px;

        font-size: 19px;

        color: #1b1b1b;
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
    }

    .product-bottom strong {
        font-size: 17px;

        color: #1b1b1b;
    }

    /* =========================================================
       BOTÓN +
    ========================================================= */

    .add {
        width: 36px;
        height: 36px;

        border: none;

        border-radius: 9px;

        background: #e63946;

        color: white;

        font-size: 20px;

        cursor: pointer;

        display: flex;

        align-items: center;
        justify-content: center;

        transition:
            transform 0.2s ease,
            background 0.2s ease,
            box-shadow 0.2s ease;
    }

    .add:hover {
        background: #c92f3b;

        transform: scale(1.08);

        box-shadow: 0 5px 15px rgba(230, 57, 70, 0.3);
    }

    .add:active {
        transform: scale(0.95);
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

    /* Animación de entrada */

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

    /* Imagen del producto */

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

            padding: 30px;
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
            width: 28%;

            min-height: 180px;
        }
    }

    /* =========================================================
       TABLETS PEQUEÑAS / MÓVILES
    ========================================================= */

    @media (max-width: 750px) {
        .content {
            margin-left: 0;

            padding: 90px 20px 25px;
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
            width: 30%;

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
            padding: 85px 15px 25px;
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
            width: 32%;

            min-height: 150px;
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
            width: 33px;
            height: 33px;

            font-size: 18px;
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
            width: 31%;

            min-height: 140px;
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
            width: 30px;
            height: 30px;

            font-size: 17px;
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
</style>
