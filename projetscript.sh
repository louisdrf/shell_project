#!/bin/bash

#si le nb d arguments est different de 1, message d'erreur
#puis on quitte
if [ $EUID -ne 0 ] 
then 
echo "vous n etes pas l utilisateur root"
exit 1
fi

if [ $# -ne 1 ]
then     echo "usage : $0 repertoire"
         exit 1
elif [ ! -f "$1" ]
then echo "largument nest pas un fichier"
        exit 1
fi

old_IFS=$IFS #on enregistre le separateur de champ 
IFS=$'\n' #nouveau separateur

for ligne in $(cat $1) 
do
         IFS=':'
         champs=($ligne)

        echo "login : ${champs[0]}"
        echo "prenom : ${champs[1]}"
        echo "nom : ${champs[2]}"
        echo "password : ${champs[${#champs[@]}-1]}"

if [ ${#champs[@]} -gt 4 ] 
then
        IFS=','
        groupes=(${champs[3]})
        echo "${groupes[*]}"
        echo "groupe primaire : ${groupes[0]} secondaire : ${groupes[*]:1}"
        
        for groupe in "${groupes[@]}"
        do
                if [ ! "$(getent group "$groupe")" ]
                then
                        echo "le groupe $groupe n existe pas, création..."
                        groupadd "$groupe"
                fi
        done

        useradd  -m -s /bin/bash -g "${groupes[0]}" -G "${groupes[*]:1}" "${champs[0]}"


#creation des utilisateurs ainsi que de leurs repertoires et fichiers

        for i in {1..4}
        do
                mkdir -p -m 755 /home/"${champs[0]}"/"rep$i"
        nbfic=$((5 + $RANDOM % 6))

        for ((j=1;j<=$nbfic;j++))
        do
                filepath="/home/${champs[0]}/rep${i}/fictest${j}"
                echo "creation de $filepath"    
                truncate -s "$((10+$RANDOM%41))M" "$filepath"
        done
        done
else
        echo "user ${champs[0]} n a pas de groupe son groupe sera ${champs[0]}"
        useradd  -m -s /bin/bash -U "${champs[0]}"
        usermod -aG "${champs[0]}" "${champs[0]}"
        for i in {1..4}
        do

                mkdir -p -m 755 /home/"${champs[0]}"/"rep$i"

        nbfic=$((5 + $RANDOM % 6))
        for ((j=1;j<=$nbfic;j++))
        do
                filepath="/home/${champs[0]}/rep${i}/fictest${j}"
                truncate -s "$((10+$RANDOM%41))M" "$filepath"
        done
        done
fi
        echo "${champs[0]}:${champs[${#champs[@]}-1]}" | chpasswd
        passwd -e "${champs[0]}"
done 
IFS=$old_IFS

