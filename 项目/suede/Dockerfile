FROM 192.168.240.73/test/node:10.15.3-cnpm 
ADD suede /suede
RUN cd /suede && npm install -g http-server && cnpm install
ENTRYPOINT [ "sh", "-c", "cd /suede && npm run dev" ] 
