<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="images/stethoscope.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">HaptiHeart: A multimodal stethoscope simulation learning tool for heart auscultation</h3>

  <p align="center">   
    By Team MedHapttan
    <br />
    Sara Badr, Naomi Catwell, Anay Karve, Soonuk Kwon
    <br />
    <br />
    CanHaptics 501 April 2024
    <br />
    <a href="https://projwinnipeg.notion.site/HaptiHeart-A-multimodal-stethoscope-simulation-learning-tool-for-heart-auscultation-c6215c1ca16a49438956757f1b8aba88?pvs=25">Read paper</a>
    ·
    <a href="https://youtu.be/5Pp0gUpgjiA">View demo</a>
    ·
    <a href="https://canhaptics.ca/">CanHaptics</a>  
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#abstract">Abstract</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABSTRACT -->
## Abstract
Heart auscultation is the process of listening to the sounds produced by the heart using a stethoscope. This is a fundamental skill for medical students. However, mastering this skill might be challenging when it comes to accurately identifying the correct anatomical positions to place the stethoscope on the chest. To address these challenges, we created a multimodal system for a stethoscope simulation to improve the learning experience of heart auscultation through haptic feedback. Although a real stethoscope does not provide haptic feedback, our system aims to facilitate learning the different auscultation areas by combining visual, auditory, and haptic modalities and reinforcing what one would hear while using an actual stethoscope with haptic force feedback synchronized with the audio of the heartbeat. This will allow users to explore and familiarize themselves with the correct anatomical positions for auscultation.

<b>Additional Keywords and Phrases:</b> Haptics, Heartbeat, Education, Multimodal, Experiential Learning

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started

This project uses Processing and requires a Haply 2diy device (version 2 or 3).

1. Clone the repository
   ```sh
   git clone https://github.com/CanHaptics-MedHapttan/StethoscopeSimulation.git
   ```

2. Install the required Processing packages
- GifAnimation 3.0.0 by Patrick Meister, Jerome Saint-Clair
- Sound 2.4.0 by The Processing Foundation

3. Connect the Haply 2diy device and retrieve the COM port number from Device Manager settings

4. In `StethoscopeSimulation.pde`, set # to your COM port number.
  ```sh
   haplyBoard          = new Board(this, "COM#", 0);
   ```
   
5. If you are using Haply 2diy version 2, uncomment the following lines :
    ```
    /*
    widgetOne.add_actuator(1, CCW, 2);
    widgetOne.add_actuator(2, CW, 1);
  
    widgetOne.add_encoder(1, CCW, 241, 10752, 2);
    widgetOne.add_encoder(2, CW, -61, 10752, 1);
    */
    ```
    and comment the following lines :

    ```
    widgetOne.add_actuator(1, CCW, 2);
    widgetOne.add_actuator(2, CCW, 1);
 
    widgetOne.add_encoder(1, CCW, 168, 4880, 2);
    widgetOne.add_encoder(2, CCW, 12, 4880, 1);
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTACT -->
## Contact

Sara Badr*, École de technologie supérieure, sara.badr.1@ens.etsmtl.ca

Naomi Catwell*, École de technologie supérieure, naomi.catwell.1@ens.etsmtl.ca

Anay Karve*, McGill University, anay.karve@mail.mcgill.ca

Soonuk Kwon*, The University of British Columbia, kwonars@student.ubc.ca

\* All authors contributed equally to the paper. 
<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

We would like to express our gratitude to Dr. Karon MacLean and Dr. Oliver Schneider for their invaluable feedback and mentorship throughout the course of the project. We would also like to extend our thanks to Dr. Vincent Lévesque for providing us with vibrotactile actuators to explore at the beginning of the project. Finally, we appreciate the support provided by the teaching assistants, Juliette Regimbal, and Sabrina Knappe, throughout the course.


<p align="right">(<a href="#readme-top">back to top</a>)</p>



