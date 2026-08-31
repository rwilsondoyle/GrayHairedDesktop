# Stage 17–19 promotion summary

Physically verified on the Dell Inspiron 3502 running Zorin OS 18.1 / GNOME Shell 46 Wayland.

- Stage 17: Manual Background override with GTK 4 `My Desktop Background` settings UI and Zorin application-menu launcher. Manual colors override Automatic Blend; returning to Automatic restores the existing appearance behavior.
- Stage 18: compact 204 px minimum icon-pane geometry. Tiny, Small, Standard, and Large were visually checked; Tiny/Small remain two columns and the webpage regains horizontal space.
- Stage 19: block `file://` WebKit navigation so accidental local-file drops cannot replace the configured desktop website. Repeated `.txt` drops were blocked and logged.

The normal installer and verifier now require these promoted behaviors. Failed/superseded Stages 8, 10, 12, 13E, and 14 remain excluded.
