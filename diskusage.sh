#!/bin/bash 

#calcul de l'usage disque de chaque utilisateur créé

users_login_size=() #liste des utilisateurs pour correspondance avec leur usage disque
sizes=()     #liste des usages disques
pairs=()     #liste des usages disques pairs
impairs=()   #liste des usages disques impairs


users=$(awk -F: '$6 ~ /^\/home\// {print $1}' /etc/passwd | grep login)

for user in $users
do 
echo "$user"
        dir_list=$(ls -d /home/"$user"/*)
        for dir in $dir_list
        do
                echo "repertoire : $dir"
                cd "$dir"
                fic_list=$(ls -l | awk '{print $5}') #recupere uniquement la taille du fichier avec ls

                for fic in $fic_list
                do
                ((dir_size+=$fic)) #on incremente la taille du repertoire pour chaque fic
                done

        echo "taille du repertoire : $dir_size"
        ((total_size+=$dir_size)) #on incremente la taille totale pour l'utilisateur pour chaque repertoire
        unset dir_size 
        done
        #((total_size/=1000000))
        users_login_size+=($user)
        users_login_size+=($total_size) #on range le nom d'utilisateur avec la taille qu il occupe

        if [ $((total_size % 2)) -eq 0 ]
        then
        pairs+=($total_size)
        else
        impairs+=($total_size)
        fi

        echo "$user utilise $total_size octets d espace disque"
        unset total_size
done

# tri pair/impair 

for ((i=0;i<${#pairs[@]};i++))
do
        for ((j=i+1;j<${#pairs[@]};j++))
        do
                if [ ${pairs[$j]} -gt ${pairs[$i]} ]
                then 
                        tmp=${pairs[$i]}
                        pairs[$i]=${pairs[$j]}
                        pairs[$j]=$tmp
                fi
        done
done

for ((i=0;i<${#impairs[@]};i++))
do
        for ((j=i+1;j<${#impairs[@]};j++))
        do
                if [ ${impairs[$j]} -gt ${impairs[$i]} ]
                then
                        tmp=${impairs[$i]}
                        impairs[$i]=${impairs[$j]}
                        impairs[$j]=$tmp
                fi
        done
done


i=0
j=0
k=0



#rangement des valeurs triées dans le bon ordre
while [ $i -lt ${#pairs[@]} ] && [ $j -lt ${#impairs[@]} ] 
do
        if [ ${impairs[$j]} -gt ${pairs[$i]} ] 
        then
                sorted_sizes[$k]=${impairs[$j]}
                ((j++))
                ((k++))
        else
                sorted_sizes[$k]=${pairs[$i]}
                ((i++))
                ((k++))
        fi
done



#on ajoute les valeurs restantes du tableau qui n a pas ete parcouru entierement
while [ $i -lt ${#pairs[@]} ]
do
        sorted_sizes[$k]=${pairs[$i]}
        ((i++))
        ((k++))
done
while [ $j -lt ${#impairs[@]} ]
do
        sorted_sizes[$k]=${impairs[$j]}
        ((j++))
        ((k++))
done


i=0
j=1
k=0

#on range les pseudos-tailles dans un nouveau tableau grace au tableau trié qu'on a obtenu
while [ $i -lt ${#sorted_sizes[@]} ]
do
        if [ $j -ge ${#users_login_size[@]} ]
        then
                j=1
        fi
        if [ "${users_login_size[$j]}" = "${sorted_sizes[$i]}" ]
        then
        #on range le nom d utilisateur avec lespace disque qu il occupe 
                user_login_sorted_sizes[$k]=${users_login_size[$j-1]}
                ((k++))
                user_login_sorted_sizes[$k]=${users_login_size[$j]}
                ((k++))
                ((i++))
        fi
                ((j+=2))
done


#on formate l'affichage de l'utilisage disque des users en Go, Mo, Ko, o
i=1
mlld=$((1000*1000*1000))
mll=$((1000*1000))
mil=1000

while [ $i -lt 10 ]
do
        newsize=0
        tmpsize=0
        finalsize=""

        s=$((${user_login_sorted_sizes[$i]}))
        if [ "$s" -ge "$mlld" ]
        then
                newsize=$(($s / $mlld))
                tmpsize=$(($newsize * $mlld))
                finalsize+=" $newsize Go "
#               echo "newsize : $newsize"
                newsize=$(($s % $tmpsize)) # on recupere la taille sans les Go 
                if [ "$newsize" -gt "$mll" ]
                then
                        newsize=$(($newsize / $mll)) # nombre de Mo
                        finalsize+=" $newsize Mo "
                        tmpsize=$(($tmpsize + ($newsize * $mll)))
#                       echo "newsize : $newsize"

                        newsize=$(($s % $tmpsize)) # on recupere la taille sans les Mo 
                        if [ "$newsize" -gt "$mil" ]
                        then
                                newsize=$(($newsize / $mil)) # nombre de Ko
                                finalsize+=" $newsize Ko "
                                tmpsize=$(($tmpsize + ($newsize * $mil)))
#                               echo "newsize : $newsize"

                                newsize=$(($s % $tmpsize)) # on recupere le nombre d'octets restants
                                if [ "$newsize" -gt 0 ]
                                then
                                        finalsize+=" $newsize octets "
                                fi
                        fi
                fi
        else
        if [ "$s" -ge "$mll" ] # si la taille fait moins d'un giga on regarde la taille en Mo ducoup
        then
                newsize=$(($s / $mll))
                tmpsize=$(($newsize * $mll))
                finalsize+=" $newsize Mo "
                newsize=$(($s % $tmpsize))
                if [ "$newsize" -gt "$mil" ] 
                then
                        newsize=$(($newsize / $mil))
                        finalsize+=" $newsize Ko "
                        tmpsize=$(($tmpsize + ($newsize * $mil)))
                        newsize=$(($s % tmpsize))
                        if [ "$newsize" -gt 0 ]
                        then
                                finalsize+=" $newsize octets "
                        fi
                fi
        fi
        fi
#       echo "print tailles : $finalsize"

        content+="user : ${user_login_sorted_sizes[$i-1]} | usage : $finalsize\n"
        ((i+=2))
done


echo "$content"

#on ecrit le classement en utilisation disque pour chaque utilisateur dans son fichier bashrc

for user in $users
do
        echostring="echo"
        echo -e  "$echostring '$content'" > "/home/"$user"/.bashrc"
done

#on écrit le script d'avertissement dans bashrc
for user in $users
do
        script=""
        script+="\n"
        script+="size=$(cat /home/"$user"/disk_usage.txt)"
        script+="\n"
        script+="if [ \$size -gt 100000000 ]"
        script+="\n"
        script+="then"
        script+="\n"
        script+="$echostring 'ATTENTION : Vous depassez la limite autorisee de 100Mo.'"
        script+="\n"
        script+="fi"
        echo -e "$script" >> "/home/"$user"/.bashrc"
done
#echo "$script"


