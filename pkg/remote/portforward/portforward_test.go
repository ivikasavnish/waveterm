// Copyright 2025, Command Line Inc.
// SPDX-License-Identifier: Apache-2.0

package portforward

import (
	"testing"
)

func TestAutoForwardDetector_Docker(t *testing.T) {
	detector := NewAutoForwardDetector()

	// Test Docker port mapping pattern
	text := "0.0.0.0:8080->80/tcp"
	forwards := detector.DetectForwards(text)

	if len(forwards) != 1 {
		t.Fatalf("expected 1 forward, got %d", len(forwards))
	}

	fwd := forwards[0]
	if fwd.LocalPort != 8080 {
		t.Errorf("expected local port 8080, got %d", fwd.LocalPort)
	}
	if fwd.RemotePort != 80 {
		t.Errorf("expected remote port 80, got %d", fwd.RemotePort)
	}
	if fwd.Source != "docker" {
		t.Errorf("expected source 'docker', got %s", fwd.Source)
	}
}

func TestAutoForwardDetector_Kubernetes(t *testing.T) {
	detector := NewAutoForwardDetector()

	// Test Kubernetes port-forward pattern
	text := "Forwarding from 127.0.0.1:8080 -> 80"
	forwards := detector.DetectForwards(text)

	if len(forwards) != 1 {
		t.Fatalf("expected 1 forward, got %d", len(forwards))
	}

	fwd := forwards[0]
	if fwd.LocalHost != "127.0.0.1" {
		t.Errorf("expected local host '127.0.0.1', got %s", fwd.LocalHost)
	}
	if fwd.LocalPort != 8080 {
		t.Errorf("expected local port 8080, got %d", fwd.LocalPort)
	}
	if fwd.RemotePort != 80 {
		t.Errorf("expected remote port 80, got %d", fwd.RemotePort)
	}
	if fwd.Source != "kubernetes" {
		t.Errorf("expected source 'kubernetes', got %s", fwd.Source)
	}
}

func TestAutoForwardDetector_Listening(t *testing.T) {
	detector := NewAutoForwardDetector()

	// Test listening pattern
	testCases := []struct {
		text string
		port int
	}{
		{"Listening on port 3000", 3000},
		{"listening on 8080", 8080},
		{"Server running on http://localhost:3000", 3000},
	}

	for _, tc := range testCases {
		forwards := detector.DetectForwards(tc.text)
		if len(forwards) != 1 {
			t.Errorf("expected 1 forward for '%s', got %d", tc.text, len(forwards))
			continue
		}
		if forwards[0].LocalPort != tc.port {
			t.Errorf("expected local port %d for '%s', got %d", tc.port, tc.text, forwards[0].LocalPort)
		}
	}
}

func TestPortForwardConfig(t *testing.T) {
	config := PortForwardConfig{
		ID:            "test-forward",
		Type:          ForwardTypeLocal,
		LocalHost:     "localhost",
		LocalPort:     8080,
		RemoteHost:    "remote",
		RemotePort:    80,
		Description:   "Test forward",
		AutoStart:     true,
		Persistent:    true,
		ConnectionKey: "user@host",
	}

	if config.ID != "test-forward" {
		t.Errorf("expected ID 'test-forward', got %s", config.ID)
	}
	if config.Type != ForwardTypeLocal {
		t.Errorf("expected type 'local', got %s", config.Type)
	}
	if config.LocalPort != 8080 {
		t.Errorf("expected local port 8080, got %d", config.LocalPort)
	}
}

func TestGetManager_Singleton(t *testing.T) {
	m1 := GetManager()
	m2 := GetManager()

	if m1 != m2 {
		t.Error("GetManager should return the same instance")
	}
}
