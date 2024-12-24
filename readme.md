VeXon : RISC-V, Perfected

https://ideas.fandom.com/wiki/Vexon

Features
- 5 stages pipeline
- Return Address Stack (ROS) [x]
- RV32I[M][C][][][]
- Prefetch Instruction Queue (PIQ) []

Branch predictors
    - 2 bit predictor []
    - Loop predictors []
    - Dedicated registers []

Macro OP Fusion list :

TODOLIST:
- Restructurer le FRONT END:
    1. Decoder par extension
        Exemple: Traiter uniquement les instructions I
        Avantage: Plus de modularité et + facile faire macro-op fusion
                  Plus facile de gérer les illégalités
    2. Superscalar: Voir signaux d'interface pour déterminer comment faire

- Restructurer le BACKEND:
    1. Ajouter des unités pour faire du superscalaire
    2. Out of Order Execution

- Définir les signaux d'interface

