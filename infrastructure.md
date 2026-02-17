# Homelab Infrastructure Overview

This document provides a visual overview of the homelab network and server rack layout, defined using Mermaid for "documentation as code."

```mermaid
graph TD
    subgraph "Internet Edge"
        I(Internet)
        UCI[Unifi UCI Modem]
    end

    subgraph "Unifi Rack 1 (Network Core)"
        direction LR
        UDMSE["UDM-SE
(Router, Firewall)"]

        USWPM24("USW Pro Max 24
(Core Switch)")
    end

    subgraph "Unifi Rack 2 (Power & UPS)"
        direction LR
        PDU["Unifi UPS PDU Pro"]
        UPS["Unifi UPS 2U"]
        RPS["Unifi USP RPS"]
    end

    subgraph "Home Devices"
        EpsonPrinter["Epson WF-4820 Series Printer\n192.168.10.5"]
    end

    subgraph "Main Server Rack"
        k8s0["k8s-0
(GEEKOM Mini IT13)
On Shelf Above Rack"]
        k8s1["k8s-1
(GEEKOM Mini IT13)
On Shelf Above Rack"]
        k8s2["k8s-2
(GEEKOM Mini IT13)
On Shelf Above Rack"]
        QNAP["QNAP TS-462 NAS
On Shelf Above Rack"]
    end

    subgraph "Distributed Switches & Access Points"
        USWUltra8["USW Ultra 8 Port
(Dist. Switch)
(Basement)"]
        USWFlex["USW Flex
(Outdoor Switch)
(Patio)"]
        U6LR_Barn["U6-LR AP (Barn)"]
        U6LR_Hallway["U6-LR AP (Hallway)"]
        U7Pro["U7 Pro AP
(Basement)"]
        U7Outdoor["U7 Outdoor AP
(Patio)"]
    end

    %% --- Internet Edge Connections ---
    I -- "Fiber/Coax" --> UCI
    UCI -- "Ethernet" --> UDMSE

    %% --- Unifi Rack 1 Internal Connections ---
    UDMSE -- "10GbE SFP+ / VLAN 1" --> USWPM24


    %% --- Inter-Rack Connections (Main Switch to Servers/NAS) ---
    USWPM24 -- "VLAN 30 (Homelab)" --> k8s0
    USWPM24 -- "VLAN 30 (Homelab)" --> k8s1
    USWPM24 -- "VLAN 30 (Homelab)" --> k8s2
    USWPM24 -- "10GbE SFP+ / VLAN 30" --> QNAP

    USWPM24 -- "Port 8" --> UPS
    USWPM24 -- "Port 9" --> PDU
    USWPM24 -- "Port 10" --> RPS
    USWPM24 -- "Port 11 / VLAN 10" --> EpsonPrinter

    USWPM24 -- "Port 23" --> U6LR_Hallway

    %% --- Power Connections (Conceptual) ---
    PDU --- UPS
    UPS --- RPS

    %% --- Distributed Network ---
    USWPM24 -- "Port 24" --> USWUltra8
    USWUltra8 -- "Downlink" --> USWFlex
    USWUltra8 --> U7Pro
            USWUltra8 --> U6LR_Barn["U6-LR AP (Barn)"]    USWFlex --> U7Outdoor["U7 Outdoor AP"]
```
