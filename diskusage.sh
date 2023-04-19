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
        ((total_size/=1000000))
        users_login_size+=($user)
        users_login_size+=($total_size) #on range le nom d'utilisateur avec la taille qu il occupe

        if [ $((total_size % 2)) -eq 0 ]
        then
        pairs+=($total_size)
        else
        impairs+=($total_size)
        fi

        echo "$user utilise $total_size Mo d espace disque"
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

sorted_sizes+=(${pairs[@]})


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

sorted_sizes+=(${impairs[@]})

k=0


for ((i=0;i<${#sorted_sizes[@]};i++))
do
        for ((j=1;j<${#usernames[@]};j+=2))
        do
                if [ "${usernames[$j]}" = "${sorted_sizes[$i]}" -a $((usernames[$j] % 2)) -eq 0 ]
                then
                pair_login_sizes_sorted[$k]=${usernames[$j-1]}
                pair_login_sizes_sorted[$k+1]=${sorted_sizes[$i]}
                user_login_sizes_sorted[$k]=${pair_login_sizes_sorted[$k]}
                user_login_sizes_sorted[$k+1]=${pair_login_sizes_sorted[$k+1]}
                ((k+=2))
                break
                else 
                if [ "${usernames[$j]}" = "${sorted_sizes[$i]}" -a $((usernames[$j] % 2)) -ne 0 ]
                then
                impair_login_sizes_sorted[$k]=${usernames[$j-1]}
                impair_login_sizes_sorted[$k+1]=${sorted_sizes[$i]}
                user_login_sizes_sorted[$k]=${impair_login_sizes_sorted[$k]}
                user_login_sizes_sorted[$k+1]=${impair_login_sizes_sorted[$k+1]}
                ((k+=2))
                break
                fi
                fi
        done
done

for ((i=1;i<${#user_login_sizes_sorted[@]};i+=2))
do
        content+="user : ${user_login_sizes_sorted[$i-1]} | usage : ${user_login_sizes_sorted[$i]} Mo\n"
done

echo -e  "$content" >"/tmp/tmp.txt"
diff "/tmp/tmp.txt" "/etc/motd"
cp "/tmp/tmp.txt" "/etc/motd"

