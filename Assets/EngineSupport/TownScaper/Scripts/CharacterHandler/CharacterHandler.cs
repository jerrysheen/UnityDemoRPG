using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterHandler : MonoBehaviour
{
    //Local variables
    float rotation = 0;
    float rotationUpDown = 0;

    //Other components
    CharacterController characterController;
    Camera cameraCharacter;

    private void Awake()
    {
        characterController = GetComponent<CharacterController>();

        cameraCharacter = GetComponentInChildren<Camera>();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        //Get input
        float forwardInput = Input.GetAxis("Vertical");
        float sideInput = Input.GetAxis("Horizontal");
        float turnInput = Input.GetAxisRaw("Mouse X");
        float lookUpInput = Input.GetAxisRaw("Mouse Y");

        //Turn the character with the mouse
        rotation += turnInput * 5;
        transform.localRotation = Quaternion.Euler(0, rotation, 0);

        //Rotate the camera up and down
        rotationUpDown -= lookUpInput * 2;
        rotationUpDown = Mathf.Clamp(rotationUpDown, -80, 80);
        cameraCharacter.transform.localRotation = Quaternion.Euler(rotationUpDown, 0 , 0);

        //Move the character forward
        characterController.SimpleMove(transform.right * sideInput + transform.forward * forwardInput * 2);
    }
}
