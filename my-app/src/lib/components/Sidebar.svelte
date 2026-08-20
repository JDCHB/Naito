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
    .sidebar {
        width: 270px;
        height: 100vh;

        background-image: linear-gradient(
                rgba(5, 5, 5, 0.58),
                rgba(5, 5, 5, 0.58)
            ),
            url("Fondos/Fondo-oscuro.jpg");

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

        box-shadow: 5px 0 20px rgba(0, 0, 0, 0.25);

        z-index: 100;
    }

    .sidebar::-webkit-scrollbar {
        display: none;
    }

    /* LOGO */

    .logo {
        display: flex;
        justify-content: center;
        margin-bottom: 40px;
    }

    .logo img {
        width: 150px;
        height: 150px;
        display: block;
        object-fit: cover;
        border-radius: 50%;
        border: 3px solid rgb(0, 0, 0);
    }

    /* SECCIONES */

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

    /* PRODUCTOS */

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

    /* REDES E INFORMACIÓN */

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

    /* ICONOS */

    .social-icon {
        width: 25px;
        height: 25px;

        border-radius: 50%;

        display: flex;
        align-items: center;
        justify-content: center;

        background: rgba(255, 255, 255, 0.08);

        font-weight: bold;
        font-size: 12px;
    }

    /* FOOTER */

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

    /* RESPONSIVE */

    @media (max-width: 700px) {
        .sidebar {
            width: 220px;
            padding: 25px 18px;
        }

        .logo {
            margin-bottom: 30px;
        }
    }
</style>
