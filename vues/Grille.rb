require 'gtk3'
Dir[File.dirname(__FILE__) + '/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/../api/*.rb'].each {|file| require file }

COUL_BLEU        = Gdk::RGBA::new(0.4, 0.7, 1.0, 1.0)
COUL_ROUGE       = Gdk::RGBA::new(1.0, 0.4, 0.4, 1.0)
COUL_VERT        = Gdk::RGBA::new(0.5, 0.9, 0.3, 1.0)
COUL_JAUNE       = Gdk::RGBA::new(1.0, 0.9, 0.3, 1.0)
COUL_JAUNE_PALE  = Gdk::RGBA::new(1.0, 0.9, 0.3, 0.4)
COUL_VIOLET      = Gdk::RGBA::new(0.7, 0.4, 0.8, 1.0)
COUL_ROSE        = Gdk::RGBA::new(0.9, 0.7, 1.0, 1.0)
COUL_BLANC       = Gdk::RGBA::new(1.0, 1.0, 1.0, 1.0)


class Grille < Gtk::Table
	@focus # case actuellement selectionné
	@partie
	@cadreAide
	@colorFocus
	@colorEquals
	@colorError
	@colorNext
	@colorNeutral

	def initialize (partie)
		super(9, 9, true)
		set_margin_left(1)

		@colorFocus = COUL_JAUNE
		@colorEquals = COUL_JAUNE_PALE
		@colorError = COUL_ROUGE
		@colorNext = COUL_VERT
		@colorNeutral = COUL_BLANC

		#==========================#
		# Remplissage de la grille #
		#==========================#
	    @partie = partie
	    @partie.creerPartie()
	    remplirGrille()
	end

	def setCaseValeur(x, y, valeur)

		#children()[81 - ((x)+((y-1)*9))].children[0].set_markup("<span size=\"x-large\" font-weight=\"bold\">#{valeur}</span>")
	end

	def setValeurSurFocus(valeur) # Mettre en place systeme focus quand click sur Case
		if (@focus)

			i = 80 - children().index(@focus)
			pos = Position.new(i%9,i/9)
			print("\n", i, " : x=",i/9, " y=", i%9)

			if (@partie.getPlateau().getCaseJoueur(pos) != valeur) && (@partie.getPlateau().getCase(pos).getOriginaleGrille == false)
				#Sauvegarde du plateau dans le undoRedo
				@partie.getUndoRedo().addMemento

				@partie.getPlateau().setCaseJoueur(pos,valeur)
				valeur = @partie.getPlateau().getCaseJoueur(pos)
				@focus.children().first().set_markup("<span size=\"x-large\" foreground=\"#4169E1\" font-weight=\"bold\">#{valeur}</span>")

				@cadreAide.setAide("Placement Numero", [valeur], "Vous avez placer la case machin")

				if(@partie.getPlateau.complete?)
					newWindow=FinJeu.new
				end
				return
			end

			if (@partie.getPlateau().getCaseJoueur(pos) == valeur) && (@partie.getPlateau().getCase(pos).getOriginaleGrille == false) # Supprime la valeur
				#Sauvegarde du plateau dans le undoRedo
				@partie.getUndoRedo().addMemento
				
				@partie.getPlateau().setCaseJoueur(pos,nil)
				valeur = @partie.getPlateau().getCaseJoueur(pos)
				@focus.children().first().set_markup("<span size=\"x-large\" foreground=\"#4169E1\" font-weight=\"bold\">#{valeur}</span>")
				return
			end
		end
	end

	def setCouleurSurFocus(couleur) # change couleur du focus
		if (@focus)
			css=<<-EOT
	   		#cell{
	      	background: #{@colorFocus};
	    	}
	    	EOT
	    	css_provider = Gtk::CssProvider.new
	    	css_provider.load :data=>css
			@focus.style_context.add_provider css_provider,GLib::MAXUINT
		end
	end

	def setColorOnValue(value, couleur)
		if (value == "")
			return
		end
		for i in 0..self.children().size()-1
			if (self.children()[i].children().first().text == value)
				css=<<-EOT
		   		#cell{
		      	background: #{@colorEquals};
		    	}
		    	EOT
		    	css_provider = Gtk::CssProvider.new
		    	css_provider.load :data=>css
				self.children()[i].style_context.add_provider css_provider,GLib::MAXUINT
			end
		end
	end

	def resetColorOnAll()
		for i in 0..self.children().size()-1
			css=<<-EOT
	   		#cell{
	      	background: #{@colorNeutral};
	    	}
	    	EOT
	    	css_provider = Gtk::CssProvider.new
	    	css_provider.load :data=>css
			self.children()[i].style_context.add_provider css_provider,GLib::MAXUINT
		end
		setCouleurSurFocus(@colorFocus)
	end

	def colorCaseResolvable()
		casesResolvable = @partie.getAide().caseResolvable()
		casesResolvable.each{ |pos|
			setCouleurCase(pos.getX(), pos.getY(), COUL_ROSE)
		}
	end

	def colorCaseIncorrect()
		listePos = @partie.getAide().verificationGrille
		if listePos.empty?
			print("\nIl n'y a pas d'erreur dans la grille")	
		else
			listePos.each { |pos|
				setCouleurCase(pos.getX(), pos.getY(), @colorError)
			}
		end

	end

	def resetCouleurSurFocus() # change couleur du focus
		if (@focus)
			css=<<-EOT
	   		#cell{
	      	background: #{@colorNeutral};
	    	}
	    	EOT
	    	css_provider = Gtk::CssProvider.new
	    	css_provider.load :data=>css
			@focus.style_context.add_provider css_provider,GLib::MAXUINT
		end
	end

	def setCouleurCase(x, y, couleur)
		css=<<-EOT
		#cell{
		background: #{couleur};
     	}
     	EOT
     	css_provider = Gtk::CssProvider.new
     	css_provider.load :data=>css
     	self.children()[81 - ((x+1)+((y)*9))].style_context.add_provider css_provider,GLib::MAXUINT
	end

	def getCoordFocus()
		if (@focus == nil)
			return
		end
		i = 80 - children().index(@focus)
		return Position.new(i%9,i/9)
	end

	def rafraichirGrille()
		@partie.getPlateau().each { |x,y,val|
			print(x , " " , y)  
			
			if(@partie.getPlateau().getCase(Position.new(x,y)).getOriginaleGrille == false)
				children()[81 - ((x+1)+((y)*9))].children().first().set_markup("<span size=\"x-large\" foreground=\"#4169E1\" font-weight=\"bold\">#{val.getSolutionJoueur}</span>")
	    	else
	    		children()[81 - ((x+1)+((y)*9))].children().first().set_markup("<span size=\"x-large\" font-weight=\"bold\">#{val.getSolutionJoueur}</span>")
	    	end
	    }
	end

	def remplirGrille()
		children().clear()
		@partie.getPlateau().each { |x,y,val|
			btn = Gtk::Button.new()
			btn.override_background_color(:normal, @colorNeutral)
			btn.signal_connect "clicked" do |widget|
				resetCouleurSurFocus()
				@focus = widget
				resetColorOnAll()
				setColorOnValue(widget.children().first().text, @colorEquals)
				setCouleurSurFocus(@colorFocus)
			end
			attach(btn, y, y+1, x, x+1, Gtk::AttachOptions::EXPAND, Gtk::AttachOptions::EXPAND, 1,0)
			btn.add(Gtk::Label.new().set_markup("<span size=\"x-large\" font-weight=\"bold\">#{val.getSolutionJoueur}</span>"))
			btn.set_size_request(46,46)
			btn.set_name "cell"
	    }
	   	resetColorOnAll()
	end

	def getPartie()
		return @partie
	end

	def setPartie(partie)
		@partie=partie
	end

	def setCadreAide(cadreAide)
		@cadreAide = cadreAide
	end

	def setColorStyle() # on définira après pour dissocier les thèmes
		@colorFocus = Gdk::RGBA::new(1.0, 1.0, 1.0, 1.0)
		@colorEquals = COUL_JAUNE_PALE
		@colorError = COUL_ROUGE
		@colorNext = COUL_VERT
		@colorNeutral = Gdk::RGBA::new(0.02, 0.00, 0.15, 1.0)

		children.each { |widget|
			widget.destroy
		}
	end
end