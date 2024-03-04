#!/bin/bash
datos_red()	#Obtener datos de red legibles al iniciar el script
{
	 echo "Información de red:"
	 echo "Dirección IP: $(hostname -I)"
	 echo "Puerta de enlace predeterminada: $(ip route | awk '/default/ {print $3}')"
	 echo "Servidor DNS: $(sudo cat /etc/resolv.conf | grep nameserver | awk '{print $2}')"
	 echo "Nombre del dispositivo: $(hostname)"
	 echo
}

mostrar_estado()	#Mostrar el estado del servicio en caso de estar ya instalado
{
	 echo "Estado del servicio Plex Media Server:"
    if [[ ! -f "/lib/systemd/system/plexmediaserver.service" ]]; then
        echo "El servicio Plex Media Server no se encuentra instalado en el sistema"
        echo
    else
        systemctl status plexmediaserver
        echo
    fi
}

instalar_plex_cli()	# Instalar Plex con comandos
{
	echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null
	curl -s https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add - > /dev/null 2>/dev/null
	sudo apt update
	sudo apt install -y plexmediaserver
 	sudo ufw allow 32400/tcp        #Abrir el puerto por defecto del servidor Plex
	echo
        echo "El servicio Plex ha sido instalado correctamente con comandos"
        echo
}

instalar_plex_ansible() 	# Instalar Plex con Ansible
{
	cd ~/ansible
	ansible-playbook -i inventory_script.ini install_plex_loopback.yml --ask-become-pass
	echo
	echo "El servicio Plex ha sido instalado correctamente con Ansible"
	echo
}

detener_plex()	# Detener Plex
{
    if [[ ! -f "/lib/systemd/system/plexmediaserver.service" ]]; then
        echo "El servicio Plex Media Server no se encuentra instalado en el sistema"
        echo
    else
        sudo systemctl stop plexmediaserver
        systemctl status plexmediaserver
        echo
        echo "El servicio Plex ha sido detenido"
        echo
    fi
}

iniciar_plex() # Arrancar Plex
{
    if [[ ! -f "/lib/systemd/system/plexmediaserver.service" ]]; then
        echo "El servicio Plex Media Server no se encuentra instalado en el sistema"
        echo
    else
        sudo systemctl start plexmediaserver
        systemctl status plexmediaserver
        echo
        echo "El servicio Plex ha sido arrancado"
        echo
    fi
}

borrar_plex() # Eliminar Plex
{
	sudo apt purge -y plexmediaserver
	echo
        echo "El servicio Plex ha sido eliminado correctamente"
        echo
}

cambiar_puerto()	# Editar puerto del servidor Plex
{
    file="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml"
    read -p "Ingrese el nuevo puerto: " nuevo_puerto

    if ! [[ $nuevo_puerto =~ ^[0-9]+$ ]]; then
        echo "Por favor, ingrese un número de puerto válido"
        return 1
    fi

    if sudo grep -q "<Setting id=\"ListenPort\" value=\"$nuevo_puerto\"/>" "$file" 2>/dev/null; then
        echo "El puerto $nuevo_puerto ya está configurado como puerto del servidor Plex"
    else
	echo "<Setting id=\"ListenPort\" value=\"$nuevo_puerto\"/>" | sudo tee -a "$file" >> /dev/null
        echo "El puerto del servicio Plex se ha cambiado exitosamente a $nuevo_puerto"
    fi
}

add_dir()	# Añadir un nuevo directorio a la biblioteca de medios
{
    file="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml"
   read -p "Ingrese la ruta de la nueva biblioteca: " new_dir
   
   if [ ! -d "$new_dir" ]; then
        echo "Error: La ruta del directorio '$new_dir' no existe."
        return 1
    fi
   
    if grep -q "<Directory path=\"$file\"/>" "$plex_media_dir"; then	# Verificar si el directorio ya está añadido a la biblioteca
        echo "El directorio $new_dir ya está añadido a la biblioteca de medios de Plex"
    else
        echo "<Directory path=\"$new_dir\"/>" | sudo tee -a "$file" >> /dev/null
        echo "El directorio $new_dir ha sido añadido a la biblioteca de medios de Plex"
    fi
}

rm_dir()	# Eliminar un directorio de la biblioteca de medios
{
    file="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml"
    read -p "Ingrese el nombre del directorio que desea eliminar: " dir_path
    
    if sudo grep -q "<Directory path=\"$dir_path\"/>" "$file"; then
        sudo sed -i "\|<Directory path=\"$dir_path\"/>|d" "$file"
        echo "El directorio $dir_path ha sido eliminada correctamente de la biblioteca de medios de Plex"
    else
        echo "El directorio $dir_path no se encuentra en la biblioteca de medios de Plex"
    fi
}

menu()	# Mostrar el menú
{
	echo "--------------------------------------------------------"
	echo "Bienvenido al script de automatización del servicio Plex"
	echo "Estas son las opciones disponibles:"
	echo "1a. Instalar Plex con comandos"
	echo "1b. Instalar Plex con Ansible"
	echo "2. Detener Plex"
	echo "3. Arrancar Plex"
	echo "4. Eliminar Plex"
	echo "5. Editar opciones de configuración"
	echo "6. Salir"
	echo "--------------------------------------------------------"
}

menu_configuracion()	# Mostrar el submenú de configuración
{
	echo
	echo "--------------------------------------------------------"
	echo "Opciones a editar de la configuración:"
	echo "a. Cambiar puerto de escucha"
	echo "b. Añadir un directorio a la biblioteca"
	echo "c. Eliminar un directorio de la biblioteca"
	echo "d. Volver al menú principal"
	echo "--------------------------------------------------------"
}

datos_red
mostrar_estado

while true; do
	menu
	read -p "Seleccione una opción: " opcion
	case $opcion in
		1a)
			instalar_plex_cli
			;;

		1b)
			instalar_plex_ansible
			;;

		2)
			detener_plex
			;;
		3)
			iniciar_plex
			;;
		4)
			borrar_plex
			;;
		5)
		while true; do
			menu_configuracion
			read -p "Ingrese la opción deseada: " conf_option
		case $conf_option in
			a)
				cambiar_puerto
				;;
			b)
				add_dir
				;;
			c)
				rm_dir
				;;
			d)
				echo
				break
				;;
			*)
				echo "Esa opción no es válida"
				echo
				;;
			esac
		done
		;;

		6)
			echo "Adios"
			exit 0
			;;
		*)
			echo "Esa opción no es válida"
			echo
			;;
	esac
done
