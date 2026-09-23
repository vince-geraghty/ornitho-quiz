<?php
require_once __DIR__ . "/../models/Oiseau.php";

class BirdnetController
{
    private Oiseau $oiseau;

    public function __construct()
    {
        $this->oiseau = new Oiseau;
    }
    /**
     * Page principale d'identification BirdNET
     */
    public function index()
    {
        require_once __DIR__ . '/../views/birdnet/birdnet.php';
    }

    /**
     * API endpoint : cherche une espèce dans la BDD par nom latin
     * Appelé en AJAX depuis le JS après analyse BirdNET
     */
    public function matchSpecies(){
    header('Content-Type: application/json');

        $nomLatin = $_GET['nom_latin'] ?? '';

        if (empty($nomLatin)) {
            echo json_encode(['found' => false]);
            return;
        }

        // Chercher par nom latin exact
        $oiseau = $this->oiseau->findByNomLatin($nomLatin);

        if ($oiseau) {
            echo json_encode([
                'found' => true,
                'id' => $oiseau['id'],
                'nom_commun' => $oiseau['nom_commun'],
                'nom_latin' => $oiseau['nom_latin'],
                'url' => '/oiseau/' . $oiseau['id']
            ]);
        } else {
            echo json_encode([
                'found' => false,
                'nom_latin' => $nomLatin
            ]);
        }
    }
}