This small Byond program takes all the icons in SpritesToSnip.dmi, 
cuts them using all the icons in Taur_Cutter.dmi, and produces a file save
dialog for you to download the resulting DMI.

Useful for cutting up species sprites from full body ones. Or whatever else.

--Arokha/Aronai


-- Hijacked by Poojawa to facilitate easier sprite porting -> tauric sprites. 

SpritesToSnip is full of Wolf taur suits, so feel free to just import a smaller .dmi and rename as needed

Take a species of taur from taur_clothing_template.dmi and paste into Taur_cutter.dmi.

Optimally you'll want to have used the suit_templates.dmi in the icon/inventory/suit folder to get a basic wolf taur outline done up. 

If the species is in taursuits_unsuitable.dmi then they won't get the benefits of these suits. That'll take changing in their sprite_accessories_taur.dm listing. It's an all-or-nothing type overhaul, so you'll need every listed suit in that species' suit file. 

In Dreammaker -> Build -> Compile and Run -> Begin the decimation. Save as whatever. The default is taursuit_.dmi so you can just slap your species in and go. Update SpritesToSnip with your wolftaur varient suit to make future organizing of the sprites easier. 

if you're just doing a limited run of one suit icon, you can throw all the relevant species into Taur_cutter, the resulting file will contain all tauric versions of your clothing item after cutout.

If You're porting a new taur entirely:
Be sure to add pixel padding, the assembled human sprite has some. The purple outline is the padding. This accounts for stuff like armor vests or heavier coats/suits. You'll want enough to work with to follow up and edit.