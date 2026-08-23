<script>
    import { supabase } from "$lib/supabase";
    import { goto } from "$app/navigation";

    let email = $state("");
    let password = $state("");
    let errorMessage = $state("");
    let loading = $state(false);

    async function iniciarSesion() {
        errorMessage = "";
        loading = true;

        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });

        loading = false;

        if (error) {
            console.error("Error iniciando sesión:", error);
            errorMessage = "Correo o contraseña incorrectos.";
            return;
        }

        console.log("Usuario autenticado:", data.user);

        goto("/salchipapa");
    }
</script>

<div class="login-container">
    <div class="login-box">
        <h1>Panel Administrativo</h1>

        <p>Inicia sesión para administrar el catálogo.</p>

        <form
            onsubmit={(event) => {
                event.preventDefault();
                iniciarSesion();
            }}
        >
            <label for="email">Correo</label>

            <input
                id="email"
                type="email"
                bind:value={email}
                placeholder="Correo de la administradora"
                required
            />

            <label for="password">Contraseña</label>

            <input
                id="password"
                type="password"
                bind:value={password}
                placeholder="Contraseña"
                required
            />

            {#if errorMessage}
                <p class="error">{errorMessage}</p>
            {/if}

            <button type="submit" disabled={loading}>
                {loading ? "Iniciando sesión..." : "Iniciar sesión"}
            </button>
        </form>
    </div>
</div>

<style>
    /* ==========================================
   FONDO DEL LOGIN
========================================== */

    :global(body) {
        margin: 0;

        background: radial-gradient(
                circle at 50% 35%,
                rgba(157, 21, 21, 0.16),
                transparent 35%
            ),
            radial-gradient(
                circle at 80% 80%,
                rgba(212, 175, 55, 0.05),
                transparent 30%
            ),
            #0d0d0d;

        color: #f5f1e8;

        font-family: Arial, Helvetica, sans-serif;
    }

    /* ==========================================
   CONTENEDOR
========================================== */

    .login-container {
        min-height: 100vh;

        display: flex;

        justify-content: center;
        align-items: center;

        padding: 20px;

        box-sizing: border-box;
    }

    /* ==========================================
   CAJA DEL LOGIN
========================================== */

    .login-box {
        position: relative;

        width: 100%;
        max-width: 420px;

        padding: 40px;

        box-sizing: border-box;

        border-radius: 18px;

        background: linear-gradient(145deg, #1b1b1b, #101010);

        border: 1px solid rgba(212, 175, 55, 0.25);

        box-shadow: 0 25px 70px rgba(0, 0, 0, 0.65);

        overflow: hidden;
    }

    /* ==========================================
   DETALLE ROJO SUPERIOR
========================================== */

    .login-box::before {
        content: "";

        position: absolute;

        top: 0;
        left: 0;
        right: 0;

        height: 4px;

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
   TÍTULO
========================================== */

    h1 {
        margin: 0 0 10px;

        color: #d4af37;

        font-size: 30px;

        font-weight: 700;

        letter-spacing: 1px;
    }

    /* ==========================================
   DESCRIPCIÓN
========================================== */

    .login-box > p {
        margin: 0 0 30px;

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
    }

    /* ==========================================
   LABELS
========================================== */

    label {
        color: #ddd;

        font-size: 14px;

        font-weight: 600;

        margin-top: 8px;
    }

    /* ==========================================
   INPUTS
========================================== */

    input {
        width: 100%;

        box-sizing: border-box;

        padding: 13px 14px;

        margin-bottom: 8px;

        background: #0c0c0c;

        color: #eee;

        border: 1px solid #353535;

        border-radius: 8px;

        outline: none;

        font-family: inherit;

        font-size: 14px;

        transition:
            border-color 0.2s ease,
            box-shadow 0.2s ease,
            background 0.2s ease;
    }

    input::placeholder {
        color: #666;
    }

    input:focus {
        background: #101010;

        border-color: #d4af37;

        box-shadow: 0 0 0 2px rgba(212, 175, 55, 0.1);
    }

    /* ==========================================
   BOTÓN
========================================== */

    button {
        width: 100%;

        margin-top: 12px;

        padding: 13px;

        border: 1px solid #b51c1c;

        border-radius: 8px;

        background: linear-gradient(135deg, #8f1111, #b51c1c);

        color: white;

        font-size: 14px;

        font-weight: 700;

        letter-spacing: 0.3px;

        cursor: pointer;

        transition:
            transform 0.2s ease,
            box-shadow 0.2s ease,
            background 0.2s ease,
            border-color 0.2s ease;
    }

    button:hover:not(:disabled) {
        transform: translateY(-2px);

        background: linear-gradient(135deg, #b51c1c, #c92323);

        border-color: #d4af37;

        box-shadow: 0 8px 25px rgba(157, 21, 21, 0.35);
    }

    button:active:not(:disabled) {
        transform: translateY(0);
    }

    /* ==========================================
   BOTÓN DESACTIVADO
========================================== */

    button:disabled {
        cursor: not-allowed;

        opacity: 0.55;

        box-shadow: none;
    }

    /* ==========================================
   ERROR
========================================== */

    .error {
        margin: 5px 0;

        padding: 10px 12px;

        background: rgba(180, 20, 20, 0.1);

        border: 1px solid rgba(180, 20, 20, 0.3);

        border-left: 3px solid #c21d1d;

        border-radius: 6px;

        color: #ef7373;

        font-size: 13px;
    }

    /* ==========================================
   RESPONSIVE
========================================== */

    @media (max-width: 500px) {
        .login-container {
            padding: 15px;
        }

        .login-box {
            padding: 30px 25px;
        }

        h1 {
            font-size: 25px;
        }
    }
</style>
