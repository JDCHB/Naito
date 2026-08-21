<script>
    let activeCategory = $state("Ramens");

    const categorias = ["Ramens", "Bebidas", "Snacks"];

    let { onCategoryChange } = $props();
</script>

<aside class="sidebar">
    <!-- LOGO -->
    <div class="logo">
        <img src="/Logo.jpeg" alt="Naito House" />
    </div>

    <!-- PRODUCTOS -->
    <div class="section">
        <h2>Productos</h2>

        <nav>
            {#each categorias as categoria}
                <button
                    class:active={activeCategory === categoria}
                    onclick={() => {
                        activeCategory = categoria;
                        onCategoryChange?.(categoria);
                    }}
                >
                    {#if categoria === "Ramens"}
                        🍜
                    {:else if categoria === "Bebidas"}
                        🥤
                    {:else}
                        🍿
                    {/if}

                    <span>{categoria}</span>
                </button>
            {/each}
        </nav>
    </div>

    <!-- REDES SOCIALES -->
    <div class="section">
        <h2>Redes sociales</h2>

        <div class="socials">
            <a href="/" onclick={(e) => e.preventDefault()}>
                <span class="social-icon">◎</span>
                Instagram
            </a>

            <a href="/" onclick={(e) => e.preventDefault()}>
                <span class="social-icon">◉</span>
                WhatsApp
            </a>

            <a href="/" onclick={(e) => e.preventDefault()}>
                <span class="social-icon">f</span>
                Facebook
            </a>
        </div>
    </div>

    <!-- INFORMACIÓN -->
    <div class="section">
        <h2>Información</h2>

        <div class="about">
            <a href="/" onclick={(e) => e.preventDefault()}> Quiénes somos </a>

            <a href="/" onclick={(e) => e.preventDefault()}> Contacto </a>
        </div>
    </div>

    <!-- FOOTER -->
    <div class="sidebar-footer">
        <p>© 2026 Naito House</p>
    </div>
</aside>

<style>
    /* ========================================
       SIDEBAR - ESCRITORIO
    ======================================== */

    .sidebar {
        width: 270px;
        height: 100vh;

        background-image: linear-gradient(
                rgba(5, 5, 5, 0.58),
                rgba(5, 5, 5, 0.58)
            ),
            url("/Fondos/Fondo-oscuro.jpg");

        background-size: 180px 180px;
        background-repeat: repeat;

        color: white;

        padding: 30px 22px;

        box-sizing: border-box;

        display: flex;
        flex-direction: column;

        position: fixed;

        left: 0;
        top: 0;

        overflow-y: auto;

        scrollbar-width: none;
        -ms-overflow-style: none;

        box-shadow: 5px 0 20px rgba(0, 0, 0, 0.25);

        z-index: 1000;
    }

    /* Ocultar scrollbar */

    .sidebar::-webkit-scrollbar {
        display: none;
    }

    /* ========================================
       LOGO
    ======================================== */

    .logo {
        display: flex;
        justify-content: center;
        align-items: center;

        margin-bottom: 40px;
    }

    .logo img {
        width: 150px;
        height: 150px;

        display: block;

        object-fit: cover;

        border-radius: 50%;

        border: 3px solid rgb(0, 0, 0);

        transition:
            width 0.3s ease,
            height 0.3s ease;
    }

    /* ========================================
       SECCIONES
    ======================================== */

    .section {
        margin-bottom: 30px;
    }

    .section h2 {
        color: #888;

        font-size: 11px;

        text-transform: uppercase;

        letter-spacing: 1.6px;

        margin: 0 0 12px;
    }

    /* ========================================
       PRODUCTOS / CATEGORÍAS
    ======================================== */

    nav {
        display: flex;

        flex-direction: column;

        gap: 6px;
    }

    nav button {
        width: 100%;

        border: none;

        background: transparent;

        color: #c8c8c8;

        padding: 12px 14px;

        border-radius: 10px;

        text-align: left;

        cursor: pointer;

        font-size: 15px;

        display: flex;

        align-items: center;

        gap: 12px;

        transition: all 0.2s ease;
    }

    nav button:hover {
        background: rgba(255, 255, 255, 0.08);

        color: white;

        transform: translateX(3px);
    }

    nav button.active {
        background: #e63946;

        color: white;

        box-shadow: 0 5px 15px rgba(230, 57, 70, 0.25);
    }

    /* ========================================
       REDES E INFORMACIÓN
    ======================================== */

    .socials,
    .about {
        display: flex;

        flex-direction: column;

        gap: 10px;
    }

    .socials a,
    .about a {
        color: #c8c8c8;

        text-decoration: none;

        font-size: 14px;

        display: flex;

        align-items: center;

        gap: 12px;

        transition: all 0.2s ease;
    }

    .socials a:hover,
    .about a:hover {
        color: white;

        transform: translateX(3px);
    }

    /* ========================================
       ICONOS
    ======================================== */

    .social-icon {
        width: 25px;
        height: 25px;

        flex-shrink: 0;

        border-radius: 50%;

        display: flex;

        align-items: center;
        justify-content: center;

        background: rgba(255, 255, 255, 0.08);

        font-weight: bold;

        font-size: 12px;
    }

    /* ========================================
       FOOTER
    ======================================== */

    .sidebar-footer {
        margin-top: auto;

        padding-top: 20px;

        border-top: 1px solid rgba(255, 255, 255, 0.12);
    }

    .sidebar-footer p {
        color: #666;

        font-size: 11px;

        margin: 0;
    }

    /* ========================================
       TABLETS
       701px - 1000px
    ======================================== */

    @media (max-width: 1000px) {
        .sidebar {
            width: 220px;

            padding: 25px 18px;
        }

        /* LOGO */

        .logo {
            margin-bottom: 30px;
        }

        .logo img {
            width: 120px;
            height: 120px;
        }

        /* SECCIONES */

        .section {
            margin-bottom: 25px;
        }

        /* CATEGORÍAS */

        nav button {
            padding: 11px 12px;

            font-size: 14px;
        }

        /* REDES */

        .socials a,
        .about a {
            font-size: 13px;
        }
    }

    /* ========================================
       TABLETS PEQUEÑAS
       551px - 700px
    ======================================== */

    @media (max-width: 700px) {
        .sidebar {
            width: 190px;

            padding: 20px 14px;
        }

        /* LOGO */

        .logo {
            margin-bottom: 25px;
        }

        .logo img {
            width: 105px;
            height: 105px;
        }

        /* SECCIONES */

        .section {
            margin-bottom: 22px;
        }

        .section h2 {
            font-size: 10px;

            letter-spacing: 1.3px;
        }

        /* CATEGORÍAS */

        nav {
            gap: 4px;
        }

        nav button {
            padding: 10px;

            font-size: 13px;

            gap: 9px;
        }

        /* REDES E INFORMACIÓN */

        .socials,
        .about {
            gap: 8px;
        }

        .socials a,
        .about a {
            font-size: 12px;

            gap: 9px;
        }

        /* ICONOS */

        .social-icon {
            width: 22px;
            height: 22px;

            font-size: 11px;
        }

        /* FOOTER */

        .sidebar-footer {
            padding-top: 15px;
        }

        .sidebar-footer p {
            font-size: 10px;
        }
    }

    /* ========================================
       CELULARES
       550px O MENOS

       El sidebar se convierte en una
       barra superior horizontal.
    ======================================== */

    @media (max-width: 550px) {
        .sidebar {
            width: 100%;

            height: auto;

            min-height: 70px;

            padding: 10px 15px;

            display: flex;

            flex-direction: row;

            align-items: center;

            gap: 15px;

            overflow-x: auto;

            overflow-y: hidden;

            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.25);
        }

        /* ====================================
           LOGO
        ==================================== */

        .logo {
            margin: 0;

            flex-shrink: 0;
        }

        .logo img {
            width: 50px;
            height: 50px;

            border-width: 2px;
        }

        /* ====================================
           SECCIONES
        ==================================== */

        .section {
            margin: 0;

            flex-shrink: 0;
        }

        /* Ocultar títulos en móvil */

        .section h2 {
            display: none;
        }

        /* ====================================
           CATEGORÍAS
        ==================================== */

        nav {
            flex-direction: row;

            gap: 6px;
        }

        nav button {
            width: auto;

            padding: 9px 12px;

            border-radius: 9px;

            font-size: 13px;

            gap: 5px;

            white-space: nowrap;
        }

        nav button:hover {
            transform: none;
        }

        /* ====================================
           REDES SOCIALES
        ==================================== */

        .socials {
            flex-direction: row;

            gap: 6px;
        }

        .socials a {
            width: 36px;
            height: 36px;

            justify-content: center;

            font-size: 0;

            gap: 0;
        }

        .social-icon {
            width: 28px;
            height: 28px;

            font-size: 12px;
        }

        /* ====================================
           INFORMACIÓN

           Se oculta en móvil para evitar
           saturar la barra superior.
        ==================================== */

        .section:has(.about) {
            display: none;
        }

        /* ====================================
           FOOTER
        ==================================== */

        .sidebar-footer {
            display: none;
        }
    }

    /* ========================================
       CELULARES PEQUEÑOS
       380px O MENOS
    ======================================== */

    @media (max-width: 380px) {
        .sidebar {
            padding: 8px 10px;

            gap: 10px;
        }

        /* LOGO */

        .logo img {
            width: 44px;
            height: 44px;
        }

        /* CATEGORÍAS */

        nav {
            gap: 4px;
        }

        nav button {
            padding: 8px 9px;

            font-size: 12px;
        }

        /* REDES */

        .socials a {
            width: 32px;
            height: 32px;
        }

        .social-icon {
            width: 25px;
            height: 25px;
        }
    }
</style>
