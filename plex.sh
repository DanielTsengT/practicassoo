#!/bin/bash
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
	sudo systemctl stop plexmediaserver
	sudo systemctl status plexmediaserver
	echo
	echo "El servicio Plex ha sido detenido"
	echo
}

iniciar_plex() # Arrancar Plex
{
	sudo systemctl start plexmediaserver
	sudo systemctl status plexmediaserver
	echo
	echo "El servicio Plex ha sido arrancado"
	echo
}

borrar_plex() # Eliminar Plex
{
	sudo apt purge -y plexmediaserver
	echo
        echo "El servicio Plex ha sido eliminado correctamente"
        echo
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
	echo "b. Añadir un directorio de la biblioteca"
	echo "c. Eliminar un directorio de la biblioteca"
	echo "d. Habilitar/Deshabilitar acceso remoto"
	echo "e. Volver al menú principal"
	echo "--------------------------------------------------------"
}

add_dir()	# Añadir un nuevo directorio a la biblioteca
{
	read -p "Ingrese la ruta del directorio a añadir: " new_dir
}

rm_dir()	# Eliminar un directorio de la biblioteca
{
	read -p "Ingrese la ruta del directorio a eliminar:"  dir_to_remove 
}

remote_access()		# Habilitar o deshabilitar el acceso remoto
{
    read -p "¿Desea habilitar el acceso remoto? (S/N): " enable_remote
}
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
				remote_access
				;;
			e)
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
