<?php
namespace Adminer;

function adminer_object() {
    class AutoLoginAdminer extends Adminer {
        function credentials() {
            return ['db', 'postgres', 'postgres'];
        }

        function database() {
            return 'desafio4_development';
        }

        function login($login, $password) {
            return true;
        }

        function loginForm() {
            echo '<form action="" method="post">';
            echo '<input type="hidden" name="auth[driver]" value="pgsql">';
            echo '<input type="hidden" name="auth[server]" value="db">';
            echo '<input type="hidden" name="auth[username]" value="postgres">';
            echo '<input type="hidden" name="auth[password]" value="postgres">';
            echo '<input type="hidden" name="auth[db]" value="desafio4_development">';
            echo '<input type="submit" value="Entrar">';
            echo '</form>';
            echo '<script>document.querySelector("form").submit();</script>';
        }
    }
    return new AutoLoginAdminer;
}

include './adminer.php';
