ARG VERSION=latest
FROM odoo:${VERSION}
ARG VERSION
LABEL maintainer="Poonlap V. <poonlap@tanabutr.co.th>"

USER root
RUN echo "Building Docker image for Odoo version $VERSION" 
    
# Generate locale, set timezone
RUN apt-get update \
	&& apt-get -yq install locales tzdata git curl fonts-tlwg-laksaman\
	&& sed -i 's/# th_/th_/' /etc/locale.gen \
	&& locale-gen \
    && cp /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Add Odoo Repository for upgrading and commit the image
RUN curl https://nightly.odoo.com/odoo.key | apt-key add - \
	&& echo "deb http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list

# Add OCA modules via git
# delete sed line when l10n_th v13 is released
RUN if [ ${VERSION} = 13.0  ] || [ ${VERSION} = 'latest' ]; then l10n_th_v='12.0'; else l10n_th_v=${ODOO_VERSION}; fi \
	&& echo "l10n_th modules: " ${l10n_th_v} \
	&& mkdir -p /opt/odoo/addons \ 
	&& cd /opt/odoo/addons \
	&& git clone --single-branch --branch ${l10n_th_v} https://github.com/OCA/l10n-thailand.git \
	&& if [ ${VERSION} = 12.0 ]; then git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/server-tools.git; \
	   git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/server-ux.git; \
	   git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/reporting-engine.git; fi \
        && git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/web.git \
	&& sed -i s/${l10n_th_v}/${ODOO_VERSION}/ /opt/odoo/addons/l10n-thailand/l10n_th_partner/__manifest__.py

RUN pip3 install num2words xlwt xlrd openpyxl --no-cache-dir 


COPY ./odoo-12.0.conf ./odoo.conf /etc/odoo/
RUN if [ ${VERSION} = 12.0 ]; then mv -v /etc/odoo/odoo-12.0.conf /etc/odoo/odoo.conf; fi \
	&& chown odoo /etc/odoo/odoo.conf

USER odoo
