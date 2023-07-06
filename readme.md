NginxProxySetup is a tool that can assist you in building basic configurations for reverse proxy and securing your site with Certbot.

Please note that you need to have port 80 and 443 open to your NGINX server for this tool to work.

To run the script, follow these steps:

+ Download the script to your NGINX server.
+ Make the script executable by running the following command:

        sudo chmod +x ./nginxproxysetup.sh

This command ensures that the script can be executed.
Once the script is set to be executed, run the follwing command:

    ./nginxproxysetup.sh

This should now prompt you for information like your proxy address as well as the address the proxy server should serve the content to as example:

    (e.g., example.com): " proxy_address
    (e.g., http://localhost:8000): " target_address

You can also modify the target_address to work with application as well as example:

    http://localhost:8000/application