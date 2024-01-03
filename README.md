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


**CentOS Sunucu İşlemleri:**

1.  **Nginx Web Server Kurulumu:** Şimdi CentOS sunucuya Nginx web server'ı atıyoruz.
    
    
 

>    `sudo yum install nginx`

    
2.  **Nginx Servisinin Otomatik Başlaması:** Nginx'in kendi kendine başlaması için bir ayar yapıyoruz.
    
   
  

>   `sudo systemctl enable nginx`

    
3.  **WordPress İçin Gerekli PHP Paketlerinin Kurulması:** WordPress işlerini çözebilmek için gerekli PHP paketlerini çakıyoruz.
    
    

> `sudo yum install php php-fpm php-mysql`

    
4.  **WordPress İçin Nginx/PHP Yapılandırmalarının Yapılması:** Nginx ve PHP-FPM yapılandırmalarını, WordPress'e selam verecek şekilde ayarlıyoruz.
    
5.  **WordPress İndirilip Dizine Açılması:** WordPress arşivini indirip /tmp'ye atıyoruz, sonra /var/www/wordpress2023 dizinine patlatıyoruz.
        
   

>  `wget -P /tmp https://wordpress.org/latest.tar.gz
>     tar -xzvf /tmp/latest.tar.gz -C /var/www/`


![FrMr2jtWcAIGr-y](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/92192038-ba31-499e-a90d-f0f79d086329)


    
6.  **Nginx Yapılandırmasının Güncellenmesi:** /etc/nginx/nginx.conf dosyası güncellendiğinde, Nginx servisini reload etme ayarı yapıyoruz.
    
7.  **wp-config.php Dosyasının Düzenlenmesi:** WordPress'in wp-config.php dosyasındaki veritabanı bilgilerini açıp düzenleyip gizli anahtarları alıp dolduruyoruz.
    
8.  **Self-signed SSL Sertifikası Oluşturulması ve Nginx Yapılandırmasına Eklenmesi:** Kendi kendine imzalı SSL sertifikası yaratıp, Nginx yapılandırmasına ekliyoruz.



Bu kısımlarda çok sorun yaşadım. Yapay zeka desteği aldık üzgün kedi reisle beraber.
![images](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/3224a5aa-60b1-48c7-b5ad-d90f284506d0)


    
9.  **Nginx Yapılandırmasının Salt ile Yönetilmesi:** Nginx'in yapılandırmasını Salt ile ayarlıyoruz, Salt dosyası uygulandığında /etc/nginx/nginx.conf dosyası, Salt'ın files dizinindeki nginx.conf dosyasından güncelleniyor.
    
10.  **Nginx Servisinin Ayın İlk Gününde Yeniden Başlatılacak Cron'un Oluşturulması:** Nginx servisini ayın ilk gününde kapatıp yeniden başlatan bir cron oluşturuyoruz.
    
11.  **Nginx Loglarının Logrotate ile Yönetilmesi:** Nginx loglarını saat başı döndüren, döndürülen log dosyalarını zipleyen ve sadece son 10 dosyayı tutan bir logrotate ayarı yapılıyor.
    

**Ubuntu Sunucu İşlemleri:**

1.  **MySQL Veritabanı Kurulumu ve Otomatik Başlama Yapılandırılması:** MySQL veritabanını takıp, servisin sunucu yeniden başladığında kendiliğinden başlaması için bir şeyler ayarlanıyor.
    
2.  **WordPress İçin MySQL Veritabanı ve Kullanıcı Oluşturulması:** WordPress kurulacağı için MySQL üzerinde veritabanı ve kullanıcı yaratılıp, gerekli yetkiler düzenleniyor.


State dosyasına DB bilgileri eklendi. Ama masterda çalıştırırken hatalar gel gel yapıyordu.

Nasıl mı? yakışıklı güvenlik gibi :(
![yakışıklı-güvenlik-yakisikli-guvenlik](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/40c4fd46-6e14-4994-9d6f-0f17a59d76ff)



    
3.  **MySQL Database Dump'ının Her Gece 02:00'de Alınacak Cron'un Hazırlanması:** Gecenin bi' yarısında MySQL database dump'ını alıp /backup dizinine atan bir cron işlemi kuruluyor.

## Master sunucudaki ekran çıktıları

Bende çıkan hataların sizde çıkmamasını temenni ediyorum...
1 - Test
![pin-test](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/8f539a29-40f0-4ba0-a7dc-1b489983e57b)

2 Ubuntu 

![Ubuntu Sonuc-1](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/efa1ee14-5f34-4352-b886-62291789995f)

3 Centos

![centos-sonuc-1](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/81abc023-2c0d-4bc7-bd7c-e18642784b06)



Bu arada nusret mesajıma neden cevap vermedi sizce?
![nusret](https://github.com/nihatbyram/Kartaca-saltstate-task/assets/30882402/6298e544-ef04-4113-a8f3-7c0aabf1a481)






























