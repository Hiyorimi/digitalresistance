check_our_ips.rb
	Есть n elastic IPs и есть n instances приязанных к ним.
	Скрипт check_our_ips.rb пробегает по всем указанным зонам и проверяет все IP на бан.
	Если IP забанен то циклично подбирается новый, пока не встретится чистый и с ним связывается инстанс (после перезагружается).


main.sh
	Бесконечная проверка check_our_ips.rb в цикле с некоторой периодичностью.

launch_valid_address.rb
	Найти чистый elastic IP и добавить.