require 'gtk3'
require './Grille'

class SousGrille < Gtk::Table # contenant elle même une grille
	@grilleCandidat
	@grille

	def new(grille)
		initialize(grille)
	end

	def initialize (grille)
		super(1,1,true)
		@grille = grille
		@grilleCandidat = Gtk::Table.new(26, 26, true)
		background = Gtk::EventBox.new().add(Gtk::Image.new( :pixbuf => GdkPixbuf::Pixbuf.new(:file => "grille.png", :width => 432, :heigth => 432)))
		attach(@grilleCandidat, 0, 1, 0, 1)
		attach(grille    , 0, 1, 0, 1)
		attach(background, 0, 1, 0, 1)

		for i in 0..26
			for y in 0..26
				@grilleCandidat.attach(Gtk::Label.new(), y, y+1, i, i+1)
			end
		end

		loadAllCandidats()
	end

	def loadAllCandidats()
		for x in 0..8
			for y in 0..8
				loadCandidatsCase(x,y)
			end
		end
	end

	def loadCandidatsCase(x, y)
		if (@grille.getPartie().getPlateau().getCaseJoueur(Position.new(x,y)) != nil)
			return
		end
		candidat = @grille.getPartie().getPlateau().candidatPossible(Position.new(x, y)).getListeCandidat()
		print("\n Candidat en #{x+1},#{y+1}: ", candidat)
		pos = (x*81 + y*3) + 1
	    for i in 0..2
		    for u in 0..2
		      	@grilleCandidat.children()[729-(pos+u+i*27)].set_markup("<span size=\"small\" foreground=\"#900090\">#{candidat[(u+i*3)+1]}</span>")
		    end
		end
	end

	def setValeurSurFocus(valeur) # Mettre en place systeme focus quand click sur Case
		if (@focus)
			#Sauvegarde du plateau dans le undoRedo
			@partie.getUndoRedo().addMemento

			i = 80 - children().index(@focus)
			pos = Position.new(i%9,i/9)
			print("\n", i, " : x=",i/9, " y=", i%9)
			@partie.getPlateau().setCaseJoueur(pos,valeur)
			valeur = @partie.getPlateau().getCaseJoueur(pos)
			@focus.children().first().set_markup("<span size=\"x-large\" font-weight=\"bold\">#{valeur}</span>")

		end
	end

end