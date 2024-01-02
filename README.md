# Kartaca-saltstate-task
Kartaca SaltStack ile Hedef Makina Yönetim / Otomasyon / Konfigürasyonu
# NOT: Görev esnasında 8 Ocak 2024 tarihine kadar bu repoda her güncelleme yapıldığında, ironilere ve yorumlara yer verilecektir.
Öncelikle SaltStack ile tanıştığımda aşırı hoşuma gitmişti ufak çapta local ortamda sanal sunucuları 
tek bir merkezde yönetmek için denemeler yaptım ancak hala olmadığı gibi Türkçe kaynakta zorlandığımdan bıraktım ama hep aklımın bir köşesindeydi.
1-2 yılın ardından Kartaca'nın bir iş ilanına başvurdum ve yine karşıma çıktı.
İlana Başvurduktan sonra aldığım görev maili ile yeniden State araştırmalarımı sürdürdüm, bu alanda ingilizcenin değerini tam anlamıyla kavradım. 
![Eqoy-c_W4AAIGte](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/236a4475-6635-4f85-b26b-35f4eada5627)

Yakın zamanda bu alanda Türkçe kaynak oluşturmayı hedefliyorum dersem yeridir.
Gerekli çalışma alanımı oluşturdum ve Salt Projesini detaylı bir şekilde araştırmaya ve Dökümanları okumaya başladım.

Kaynak: https://docs.saltproject.io/en/latest/contents.html


## CentOS Stream 9 ve Ubuntu kurulumu yapıldı
Kurulumun hemen ardından SaltStack'in depoları aşağıdaki gibi CentOs'a eklendi.

```bash
  sudo yum install -y epel-release
  sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm
```

 Minion kuruldu
 ```bash
  sudo yum install salt-minion
 ```
Minion Hizmeti enable edilip başlatıldı

 ```bash
 sudo systemctl enable salt-minion
 sudo systemctl start salt-minion
 ```
Bu işlemlerin aynısı ubuntu sunucu için de uygulandı tek tek yazmayalım tekrardan.

![maxresdefault](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/b96db290-b501-4264-89cc-9cd4fe4034ee)

Hemen ardından, master sunucuyu kurup mininonlarda Master sunucunun ip adresi eklendi.

