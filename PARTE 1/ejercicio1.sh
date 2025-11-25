#!/bin/bash

func_login(){
    login=false
    # Si le erra tres veces se sale
    local try=0
    while [[ "$login" = false && $try -lt 3 ]]; do
        ((try++)) 
        # Pedir usuario y contraseña
        read -p "Usuario: " user
        read -s -p "Contraseña: " contra
        echo

        # Verificar login
        if grep -qx "${user}:${contra}" "$FILE"; then
            echo "Login exitoso. Bienvenido, $user!"
            login=true
        else
            echo "Usuario o contraseña incorrectos."
        fi
    done
    if [ "$try" -eq 3 ]; then 
        echo "Demasiados intentos erroneos, login fallido"
    fi
}

menu(){
    salir=false
    # Muestro el menu y pido que elija que hacer hasta que decida salir
    while [ "$salir" = false ]; do
        desplegar_menu
        case "$opcion_menu" in
            1)
                desplegar_usuario
                case "$opcion_usuario" in
                    a)
                        crear_usuario
                        ;;

                    b)
                        cambiar_contra
                        ;;

                    *)
                        echo "Opcion no valida"
                        ;;
                esac
                ;;

            2)
                ingresar_producto
                ;;

            3)
                vender_producto
                ;;

            4)
                filtro_productos
                ;;

            5)
                crear_reporte
                ;;

            6)
                logout
                ;;
            7)
                salir=true
                ;;

            *)
                echo "Opcion no valida"
                ;;
        esac
    done
}

desplegar_menu(){
    echo
    echo "Elija una opcion:"
    echo "1. Administrar usuarios"
    echo "2. Ingresar producto"
    echo "3. Vender producto"
    echo "4. Listar productos"
    echo "5. Crear reporte de pinturas"
    echo "6. Logout"
    echo "7. Salir"
    read -p "Ingrese el numero de la opcion deseada: " opcion_menu
    echo
}

desplegar_usuario(){
    echo "Elija una opcion de usuario:"
    echo "a. Crear usuario"
    echo "b. Cambiar contraseña"
    read -p "Ingrese la letra de la opcion deseada: " opcion_usuario
    echo
}

crear_usuario(){
    local creado=false
    while [ "$creado" = false ]; do
        # Pido el nombre
        read -p "Ingrese nombre: " nombre
        echo
        if ! grep -q "^${nombre}:" "$FILE"; then
            # Si no existe pido la contraseña
            local valida=false
            # Valido la contraseña repitiendola para evitar errores
            while [ "$valida" = false ]; do
                read -s -p "Ingrese contraseña: " contra1
                echo
                read -s -p "Verifique la contraseña: " contra2
                if [ "$contra1" = "$contra2" ]; then
                    echo "Usuario creado exitosamente"
                    echo "${nombre}:${contra1}" >> "$FILE"
                    creado=true
                    valida=true
                else
                    echo "La verificacion no coincide"
                fi
            done
        else
            echo "Usuario '$nombre' ya esta en uso. Elija otro nombre"
        fi
    done
}

cambiar_contra() {
    read -p "Ingrese usuario a cambiar: " usuario
    echo

    # Verificar si el usuario existe
    if grep -q "^${usuario}:" "$FILE"; then
        local try=0
        local correcto=false

        # Pedir contraseña actual (máx. 3 intentos)
        while [ "$correcto" = false ] && [ $try -lt 3 ]; do
            ((try++))
            read -s -p "Ingrese contraseña actual: " viejaContra
            echo

            if grep -qx "${usuario}:${viejaContra}" "$FILE"; then
                correcto=true
            else
                echo "Contraseña incorrecta. Intento $try de 3."
            fi
        done

        if [ "$correcto" = true ]; then
            # Pide nueva contraseña y verificación
            local valida=false
            while [ "$valida" = false ]; do
                read -s -p "Ingrese nueva contraseña: " nuevaContra1
                echo
                read -s -p "Verifique la nueva contraseña: " nuevaContra2
                echo

                if [ "$nuevaContra1" = "$nuevaContra2" ]; then
                    # Reemplazar la línea en el archivo
                    sed -i "s/^${usuario}:${viejaContra}$/${usuario}:${nuevaContra1}/" "$FILE"
                    echo "Contraseña actualizada correctamente."
                    valida=true
                else
                    echo "Las contraseñas no coinciden. Intente de nuevo."
                fi
            done
        else
            echo "Demasiados intentos fallidos. Operación cancelada."
        fi
    else
        echo "El usuario '$usuario' no existe."
    fi
}

ingresar_producto() {
    echo
    echo "Ingresar producto"

    # Pedimos los datos
    read -p "Tipo de producto: " tipo
    read -p "Modelo: " modelo
    read -p "Descripción: " descripcion
    # Validar cantidad (solo número natural)
    while true; do
        read -p "Cantidad: " cantidad
        if [[ "$cantidad" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            echo "Error: Ingrese una cantidad válida (número natural mayor que 0)."
        fi
    done
    # Validar precio (solo número natural)
    while true; do
        read -p "Precio unitario: " precio
        if [[ "$precio" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            echo "Error: Ingrese un precio válido (número natural mayor que 0)."
        fi
    done

    # Generamos el código (3 primeras letras del tipo, en mayúsculas)
    codigo=$(echo "$tipo" | cut -c1-3 | tr '[:lower:]' '[:upper:]')

    # Guardamos en el archivo productos.txt
    echo "${codigo} - ${tipo} - ${modelo} - ${descripcion} - ${cantidad} - \$${precio}" >> productos.txt

    echo
    echo "Producto agregado correctamente:"
    echo "${codigo} - ${tipo} - ${modelo} - ${descripcion} - ${cantidad} - \$${precio}"
    echo
}


vender_producto() {
    echo
    echo "Lista de productos disponibles:"
    echo

    # Verificar si el archivo existe y no está vacío
    if [[ ! -s productos.txt ]]; then
        echo "No hay productos cargados."
        echo
        return
    fi

    # Mostrar productos numerados
    local contador=1
    while IFS= read -r linea; do
        tipo=$(echo "$linea" | cut -d'-' -f2 | xargs)
        modelo=$(echo "$linea" | cut -d'-' -f3 | xargs)
        precio=$(echo "$linea" | cut -d'-' -f6 | xargs)
        echo "$contador. $tipo - $modelo - $precio"
        ((contador++))
    done < productos.txt

    echo
    read -p "Ingrese los números de productos a comprar (separados por espacio): " seleccion

    total=0
    resumen=""

    for num in $seleccion; do
        linea=$(sed -n "${num}p" productos.txt)

        if [ -z "$linea" ]; then
            echo "El número $num no corresponde a ningún producto."
            continue
        fi

        tipo=$(echo "$linea" | cut -d'-' -f2 | xargs)
        modelo=$(echo "$linea" | cut -d'-' -f3 | xargs)
        stock=$(echo "$linea" | cut -d'-' -f5 | xargs)
        precio=$(echo "$linea" | cut -d'-' -f6 | tr -d '$' | xargs)

        echo
        while true; do
            read -p "Ingrese la cantidad de '$modelo' que desea comprar (stock: $stock): " cantidad
            if [[ "$cantidad" =~ ^[1-9][0-9]*$ ]]; then
                if [ "$cantidad" -le "$stock" ]; then
                    break
                else
                    echo "La cantidad ingresada supera el stock disponible."
                fi
            else
                echo "Error: Ingrese una cantidad válida (número natural mayor que 0)."
            fi
        done


        if [ "$cantidad" -le "$stock" ]; then
            precio_total=$((cantidad * precio))
            total=$((total + precio_total))
            resumen+="$tipo - $modelo - $cantidad - \$${precio_total}\n"

            # Actualizar stock en el archivo
            nuevo_stock=$((stock - cantidad))
            sed -i "${num}s/- ${stock} -/- ${nuevo_stock} -/" productos.txt
        else
            echo "La cantidad ingresada supera el stock disponible."
        fi
    done

    echo
    echo "Resumen de la compra:"
    echo -e "$resumen"
    echo "Total a pagar: \$${total}"
    echo
}

filtro_productos() {
    echo
    echo "Listar productos"
    echo

    # Verificar si el archivo existe y tiene contenido
    if [[ ! -s productos.txt ]]; then
        echo "No hay productos cargados."
        echo
        return
    fi

    # Pedir tipo para filtrar (puede dejarse vacío)
    read -p "Ingrese el tipo de producto a filtrar (o presione Enter para mostrar todos): " tipoFiltro
    echo

    # Si no se ingresa nada, mostrar todos
    if [ -z "$tipoFiltro" ]; then
        echo "Mostrando todos los productos:"
        echo
        cat productos.txt
        echo
        return
    fi

    # Filtrar por tipo (ignorando mayúsculas/minúsculas)
    resultados=$(grep -i " - ${tipoFiltro} -" productos.txt)

    if [ -z "$resultados" ]; then
        echo "No se encontraron productos del tipo '${tipoFiltro}'."
    else
        echo "Productos del tipo '${tipoFiltro}':"
        echo
        echo "$resultados"
    fi
    echo
}

crear_reporte() {
    echo
    echo "Creando reporte de pinturas..."
    echo

    # Verificar si existen productos
    if [[ ! -s productos.txt ]]; then
        echo "No hay productos cargados para generar el reporte."
        echo
        return
    fi

    # Crear carpeta Datos si no existe
    if [[ ! -d "Datos" ]]; then
        mkdir Datos
    fi

    # Generar nombre único con fecha y hora
    fecha=$(date +"%Y-%m-%d_%H-%M-%S")
    ruta="Datos/datos_${fecha}.csv"

    # Crear archivo CSV con encabezado
    echo "Codigo;Tipo;Modelo;Descripcion;Cantidad;Precio" > "$ruta"

    # Convertir el formato de productos.txt a CSV
    while IFS= read -r linea; do
        codigo=$(echo "$linea" | cut -d'-' -f1 | xargs)
        tipo=$(echo "$linea" | cut -d'-' -f2 | xargs)
        modelo=$(echo "$linea" | cut -d'-' -f3 | xargs)
        descripcion=$(echo "$linea" | cut -d'-' -f4 | xargs)
        cantidad=$(echo "$linea" | cut -d'-' -f5 | xargs)
        precio=$(echo "$linea" | cut -d'-' -f6 | tr -d '$' | xargs)
        echo "${codigo};${tipo};${modelo};${descripcion};${cantidad};${precio}" >> "$ruta"
    done < productos.txt

    echo "Reporte generado correctamente en: $ruta"
    echo
}

logout() {
    echo "Cerrando sesión..."
    echo
    salir=true
    func_login
    if [ "$login" = true ]; then
        menu
    fi
}

# Main
FILE="usuarios.txt"

# Si el archivo no existe, crearlo y agregar admin:admin
if [[ ! -f "$FILE" ]]; then
  echo "admin:admin" > "$FILE"
else
    # Si existe pero no tiene admin:admin lo agrego
    if ! grep -qx "admin:admin" "$FILE" ; then
        echo "admin:admin" >> "$FILE"
    fi
fi

echo "Bienvenido al sistema"

func_login

if [ "$login" = true ]; then
    menu
else
    echo "No se pudo iniciar sesión. Saliendo del sistema..."
fi