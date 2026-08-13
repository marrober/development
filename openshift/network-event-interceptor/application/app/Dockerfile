FROM source-image
USER 0
WORKDIR /opt/app-root/src

COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./
RUN chown -R 1001:0 /opt/app-root/src

USER 1001
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
