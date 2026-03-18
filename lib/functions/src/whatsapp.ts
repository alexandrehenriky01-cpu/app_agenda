import fetch from "node-fetch";

type SendTextParams = {
  phoneNumberId: string;        // do WhatsApp Cloud API
  accessToken: string;          // token do Meta
  to: string;                   // +5511999999999 (E.164)
  message: string;
};

type SendTemplateParams = {
  phoneNumberId: string;
  accessToken: string;
  to: string;
  templateName: string;         // nome do template criado no Meta
  languageCode?: string;        // ex: "pt_BR"
  bodyParams?: string[];        // parâmetros do template
};

export async function sendWhatsAppText(p: SendTextParams) {
  const url = `https://graph.facebook.com/v20.0/${p.phoneNumberId}/messages`;

  const payload = {
    messaging_product: "whatsapp",
    to: p.to.replace(/\D/g, ""), // WhatsApp Cloud API aceita só dígitos
    type: "text",
    text: { body: p.message },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${p.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const data = await res.json();

  if (!res.ok) {
    throw new Error(`WhatsApp API error: ${res.status} ${JSON.stringify(data)}`);
  }

  return data;
}

export async function sendWhatsAppTemplate(p: SendTemplateParams) {
  const url = `https://graph.facebook.com/v20.0/${p.phoneNumberId}/messages`;

  const payload: any = {
    messaging_product: "whatsapp",
    to: p.to.replace(/\D/g, ""),
    type: "template",
    template: {
      name: p.templateName,
      language: { code: p.languageCode ?? "pt_BR" },
    },
  };

  if (p.bodyParams?.length) {
    payload.template.components = [
      {
        type: "body",
        parameters: p.bodyParams.map((x) => ({ type: "text", text: x })),
      },
    ];
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${p.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const data = await res.json();

  if (!res.ok) {
    throw new Error(`WhatsApp API error: ${res.status} ${JSON.stringify(data)}`);
  }

  return data;
}