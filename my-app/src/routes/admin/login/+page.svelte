<script>
    import { supabase } from "$lib/supabase";
    import { goto } from "$app/navigation";

    let email = $state("");
    let password = $state("");
    let errorMessage = $state("");
    let loading = $state(false);
    let verPassword = $state(false);

    async function iniciarSesion() {
        errorMessage = "";
        loading = true;

        const { error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });

        loading = false;

        if (error) {
            console.error("Error iniciando sesión:", error);
            errorMessage = "Correo o contraseña incorrectos.";
            return;
        }

        goto("/admin");
    }
</script>

<svelte:head>
    <title>Iniciar sesión · Naito House</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
    <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Dela+Gothic+One&family=Zen+Kaku+Gothic+New:wght@400;500;700;900&display=swap"
    />
</svelte:head>

<div class="login-container">
    <div class="login-box">
        <!-- LOGO -->

        <div class="logo">
            <img src="/Logo.jpeg" alt="Naito House" />
        </div>

        <p class="eyebrow">Naito House</p>

        <h1>Panel administrativo</h1>

        <p class="subtitle">Inicia sesión para administrar el catálogo.</p>

        <form
            onsubmit={(event) => {
                event.preventDefault();
                iniciarSesion();
            }}
        >
            <label for="email">Correo</label>

            <div class="field">
                <span class="icon" aria-hidden="true">✉</span>

                <input
                    id="email"
                    type="email"
                    autocomplete="email"
                    bind:value={email}
                    oninput={() => (errorMessage = "")}
                    placeholder="correo@ejemplo.com"
                    class:invalid={errorMessage}
                    required
                />
            </div>

            <label for="password">Contraseña</label>

            <div class="field">
                <span class="icon" aria-hidden="true">🔒</span>

                <input
                    id="password"
                    type={verPassword ? "text" : "password"}
                    autocomplete="current-password"
                    bind:value={password}
                    oninput={() => (errorMessage = "")}
                    placeholder="Tu contraseña"
                    class:invalid={errorMessage}
                    required
                />

                <button
                    type="button"
                    class="toggle-password"
                    aria-label={verPassword
                        ? "Ocultar contraseña"
                        : "Mostrar contraseña"}
                    aria-pressed={verPassword}
                    onclick={() => (verPassword = !verPassword)}
                >
                    {verPassword ? "Ocultar" : "Ver"}
                </button>
            </div>

            {#if errorMessage}
                <p class="error" role="alert">
                    <span aria-hidden="true">⚠️</span>
                    {errorMessage}
                </p>
            {/if}

            <button type="submit" class="submit" disabled={loading}>
                {#if loading}
                    <span class="spinner" aria-hidden="true"></span>
                    Iniciando sesión...
                {:else}
                    Iniciar sesión
                {/if}
            </button>
        </form>

        <a class="back" href="/">← Volver al catálogo</a>
    </div>
</div>

<style>
    /* ==========================================
   FONDO DEL LOGIN
========================================== */

    :global(body) {
        margin: 0;

        background:
            radial-gradient(
                circle at 50% 30%,
                rgba(157, 21, 21, 0.2),
                transparent 40%
            ),
            radial-gradient(
                circle at 80% 85%,
                rgba(212, 175, 55, 0.06),
                transparent 30%
            ),
            #0d0d0d;
        background-attachment: fixed;

        color: #f5f1e8;

        font-family: "Zen Kaku Gothic New", Arial, Helvetica, sans-serif;

        -webkit-font-smoothing: antialiased;
    }

    /* ==========================================
   CONTENEDOR
========================================== */

    .login-container {
        min-height: 100vh;
        min-height: 100dvh;

        display: flex;
        justify-content: center;
        align-items: center;

        padding: 24px 20px;

        box-sizing: border-box;
    }

    .login-container :global(*) {
        box-sizing: border-box;
    }

    /* ==========================================
   CAJA DEL LOGIN
========================================== */

    .login-box {
        position: relative;

        width: 100%;
        max-width: 420px;

        padding: 64px 40px 32px;
        margin-top: 50px;

        border-radius: 20px;

        background: linear-gradient(160deg, #1d1d1d, #101010 60%);

        border: 1px solid rgba(212, 175, 55, 0.25);

        box-shadow:
            0 30px 80px rgba(0, 0, 0, 0.65),
            inset 0 1px 0 rgba(255, 255, 255, 0.04);

        text-align: center;

        animation: boxIn 0.5s cubic-bezier(0.22, 1, 0.36, 1);
    }

    @keyframes boxIn {
        from {
            opacity: 0;
            transform: translateY(16px);
        }
    }

    /* Detalle rojo y dorado superior */

    .login-box::before {
        content: "";

        position: absolute;
        top: 0;
        left: 24px;
        right: 24px;

        height: 3px;

        border-radius: 0 0 3px 3px;

        background: linear-gradient(
            90deg,
            #7f1010,
            #c21d1d,
            #d4af37,
            #c21d1d,
            #7f1010
        );
    }

    /* ==========================================
   LOGO
========================================== */

    .logo {
        position: absolute;
        top: -50px;
        left: 50%;

        transform: translateX(-50%);
    }

    .logo img {
        display: block;

        width: 100px;
        height: 100px;

        border-radius: 50%;
        border: 3px solid #d4af37;

        object-fit: cover;

        box-shadow:
            0 0 0 6px rgba(13, 13, 13, 0.9),
            0 12px 30px rgba(0, 0, 0, 0.6),
            0 0 40px rgba(212, 175, 55, 0.2);
    }

    /* ==========================================
   TEXTOS
========================================== */

    .eyebrow {
        margin: 0 0 6px;

        color: #9a9a9a;

        font-size: 11px;
        font-weight: 700;
        letter-spacing: 3px;
        text-transform: uppercase;
    }

    h1 {
        margin: 0 0 10px;

        color: #d4af37;

        font-family: "Dela Gothic One", sans-serif;
        font-weight: 400;
        font-size: 26px;
        line-height: 1.2;
    }

    .subtitle {
        margin: 0 0 28px;

        color: #999;

        font-size: 14px;
        line-height: 1.5;
    }

    /* ==========================================
   FORMULARIO
========================================== */

    form {
        display: flex;
        flex-direction: column;
        gap: 8px;

        text-align: left;
    }

    label {
        margin-top: 6px;

        color: #ddd;

        font-size: 13px;
        font-weight: 700;
    }

    .field {
        position: relative;

        margin-bottom: 6px;
    }

    .icon {
        position: absolute;
        left: 14px;
        top: 50%;

        transform: translateY(-50%);

        color: #777;

        font-size: 14px;

        pointer-events: none;
    }

    input {
        width: 100%;

        padding: 13px 14px 13px 40px;

        background: #0c0c0c;
        color: #eee;

        border: 1px solid #353535;
        border-radius: 10px;

        outline: none;

        font-family: inherit;
        font-size: 15px;

        transition:
            border-color 0.2s ease,
            box-shadow 0.2s ease,
            background 0.2s ease;
    }

    #password {
        padding-right: 76px;
    }

    input::placeholder {
        color: #5f5f5f;
    }

    input:focus {
        background: #101010;

        border-color: #d4af37;

        box-shadow: 0 0 0 3px rgba(212, 175, 55, 0.12);
    }

    input.invalid {
        border-color: rgba(220, 60, 60, 0.6);
    }

    .toggle-password {
        position: absolute;
        right: 6px;
        top: 50%;

        transform: translateY(-50%);

        padding: 7px 10px;

        border: none;
        border-radius: 7px;

        background: transparent;
        color: #b9a46a;

        font-family: inherit;
        font-size: 12px;
        font-weight: 700;

        cursor: pointer;

        transition:
            background 0.2s ease,
            color 0.2s ease;
    }

    .toggle-password:hover {
        background: rgba(212, 175, 55, 0.1);
        color: #d4af37;
    }

    /* ==========================================
   BOTÓN
========================================== */

    .submit {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 10px;

        width: 100%;

        margin-top: 14px;
        padding: 14px;

        border: 1px solid #b51c1c;
        border-radius: 10px;

        background: linear-gradient(135deg, #8f1111, #b51c1c);
        color: white;

        font-family: inherit;
        font-size: 15px;
        font-weight: 700;
        letter-spacing: 0.3px;

        cursor: pointer;

        box-shadow: 0 6px 20px rgba(157, 21, 21, 0.3);

        transition:
            transform 0.2s ease,
            box-shadow 0.2s ease,
            background 0.2s ease,
            border-color 0.2s ease;
    }

    .submit:hover:not(:disabled) {
        transform: translateY(-2px);

        background: linear-gradient(135deg, #b51c1c, #c92323);

        border-color: #d4af37;

        box-shadow: 0 10px 28px rgba(157, 21, 21, 0.45);
    }

    .submit:active:not(:disabled) {
        transform: translateY(0) scale(0.98);
    }

    .submit:disabled {
        cursor: progress;

        opacity: 0.7;
    }

    .spinner {
        width: 16px;
        height: 16px;

        border: 2px solid rgba(255, 255, 255, 0.35);
        border-top-color: white;
        border-radius: 50%;

        animation: spin 0.7s linear infinite;
    }

    @keyframes spin {
        to {
            transform: rotate(360deg);
        }
    }

    button:focus-visible,
    .back:focus-visible {
        outline: 2px solid #d4af37;
        outline-offset: 2px;
    }

    /* ==========================================
   ERROR
========================================== */

    .error {
        display: flex;
        align-items: center;
        gap: 8px;

        margin: 2px 0;
        padding: 10px 12px;

        background: rgba(180, 20, 20, 0.1);

        border: 1px solid rgba(180, 20, 20, 0.3);
        border-left: 3px solid #c21d1d;
        border-radius: 8px;

        color: #ef7373;

        font-size: 13px;

        animation: shake 0.35s ease;
    }

    @keyframes shake {
        25% {
            transform: translateX(-5px);
        }
        50% {
            transform: translateX(4px);
        }
        75% {
            transform: translateX(-2px);
        }
    }

    /* ==========================================
   VOLVER AL CATÁLOGO
========================================== */

    .back {
        display: inline-block;

        margin-top: 22px;

        color: #8a8a8a;

        font-size: 13px;

        text-decoration: none;

        transition: color 0.2s ease;
    }

    .back:hover {
        color: #d4af37;
    }

    /* ==========================================
   RESPONSIVE
========================================== */

    @media (max-width: 500px) {
        .login-box {
            padding: 58px 22px 26px;
        }

        .logo img {
            width: 88px;
            height: 88px;
        }

        .logo {
            top: -44px;
        }

        h1 {
            font-size: 22px;
        }
    }

    @media (prefers-reduced-motion: reduce) {
        .login-box,
        .error,
        .spinner {
            animation: none;
        }
    }
</style>
